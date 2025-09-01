public with sharing class CheckoutController {
	public class CartLine {
		@AuraEnabled public Id itemId { get; set; }
		@AuraEnabled public Integer qty { get; set; }
	}


	@AuraEnabled
	public static Id checkout(Id accountId, List<CartLine> lines) {
		if (accountId == null) {
			throw new AuraHandledException('AccountId is required.');
		}
		if (lines == null || lines.isEmpty()) {
			throw new AuraHandledException('Cart is empty.');
		}

		Map<Id, Integer> qtyByItem = new Map<Id, Integer>();
		List<String> rejected = new List<String>();

		for (CartLine l : lines) {
			if (l == null) {
				rejected.add('Line was null');
				continue;
			}
			if (String.isBlank(l.itemId)) {
				rejected.add('Line with blank itemId');
				continue;
			}
			if (l.qty == null) {
				rejected.add('Line with null qty (itemId=' + l.itemId + ')');
				continue;
			}
			if (l.qty <= 0) {
				rejected.add('Line with non-positive qty=' + l.qty + ' (itemId=' + l.itemId + ')');
				continue;
			}
			try {
				Id itemRecordId = (Id) l.itemId;
				Integer existing = qtyByItem.containsKey(itemRecordId) ? qtyByItem.get(itemRecordId) : 0;
				qtyByItem.put(itemRecordId, existing + l.qty);
			} catch (Exception e) {
				rejected.add('Invalid Id format: ' + l.itemId);
			}
		}

		if (qtyByItem.isEmpty()) {
			throw new AuraHandledException(
							'No valid cart lines. Rejected: ' + String.join(rejected, '; ')
			);
		}

		List<Item__c> items = [
				SELECT Id, Name, Price__c
				FROM Item__c
				WHERE Id IN :qtyByItem.keySet()
		];
		if (items.size() != qtyByItem.size()) {
			throw new AuraHandledException('Some items were not found. Requested='
					+ qtyByItem.keySet() + ', Found=' + items);
		}

		Purchase__c purchase = new Purchase__c(
				ClientId__c = accountId,
				Name = 'PO ' + DateTime.now().formatGmt('yyyy-MM-dd HH:mm:ss\'Z\'')
		);
		insert purchase;

		List<PurchaseLine__c> linesToInsert = new List<PurchaseLine__c>();
		for (Item__c it : items) {
			Integer q = qtyByItem.get(it.Id);
			Decimal price = it.Price__c == null ? 0 : it.Price__c;
			linesToInsert.add(new PurchaseLine__c(
					PurchaseId__c = purchase.Id,
					ItemId__c = it.Id,
					Amount__c = q,
					UnitCost__c = price
			));
		}
		insert linesToInsert;

		return purchase.Id;
	}
}
