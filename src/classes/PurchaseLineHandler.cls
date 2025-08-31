public class PurchaseLineHandler {
	public static void recalculatePurchases(Set<Id> purchaseIds) {


		List<AggregateResult> results = [
				SELECT PurchaseId__c pId,
				SUM(Amount__c) totalItems,
				SUM(TotalCost__c) grandTotal
				FROM PurchaseLine__c
				WHERE PurchaseID__c IN :purchaseIds
				GROUP BY PurchaseId__c
		];

		Map<Id, Purchase__c> toUpdate = new Map<Id, Purchase__c>();
		for (AggregateResult ar : results) {
			Id purchaseId = (Id) ar.get('pId');
			Purchase__c p = new Purchase__c(
					Id = purchaseId,
					TotalNumber__c = (Decimal) ar.get('totalItems'),
					GrandTotal__c = (Decimal) ar.get('grandTotal')
			);
			toUpdate.put(p.Id, p);
		}

		if (!toUpdate.isEmpty()) {
			update toUpdate.values();
		}
	}
}
