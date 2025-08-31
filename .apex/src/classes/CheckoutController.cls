public with sharing class CheckoutController {

	public class CartLine {
		@AuraEnabled public String itemId;
		@AuraEnabled public Integer qty;
	}

	@AuraEnabled(cacheable=false)
	public static Id checkout(Id accountId, List<CartLine> lines) {
		if (accountId == null) {
			throw new AuraHandledException('AccountId is required.');
		}
		if (lines == null || lines.isEmpty()) {
			throw new AuraHandledException('Cart is empty.');
		}

		Map<Id, Integer> qtyByItem = new Map<Id, Integer>();
		for (CartLine l : lines) {
			if (l == null || (Id)l.itemId == null || l.qty == null || l.qty <= 0) continue;
			qtyByItem.put(
					(Id)l.itemId,
							(qtyByItem.containsKey((Id)l.itemId) ? qtyByItem.get((Id)l.itemId) : 0) + l.qty
			);
		}
		if (qtyByItem.isEmpty()) {
			throw new AuraHandledException('No valid cart lines.');
		}


		List<Item__c> items = [
				SELECT Id, Name, Price__c
				FROM Item__c
				WHERE Id IN :qtyByItem.keySet()
		];
		if (items.isEmpty() || items.size() != qtyByItem.size()) {
			throw new AuraHandledException('Some items were not found.');
		}


		Purchase__c purchase = new Purchase__c(
				ClientId__c = accountId,
				Name = 'PO ' + DateTime.now().formatGmt('yyyy-MM-dd HH:mm:ss\'Z\'')
		);
		insert purchase;

		List<PurchaseLine__c> linesToInsert = new List<PurchaseLine__c>();
		for (Item__c it : items) {
			Integer q = qtyByItem.get(it.Id);
			Decimal price = (it.Price__c == null ? 0 : it.Price__c);

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
