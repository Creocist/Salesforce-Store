trigger PurchaseLineTrigger on PurchaseLine__c (after insert, after update, after delete, after undelete) {
	Set<Id> purchaseIds = new Set<Id>();

	if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
		for (PurchaseLine__c line : Trigger.new) {
			if (line.PurchaseId__c != null) {
				purchaseIds.add(line.PurchaseId__c);
			}
		}
	}
	if (Trigger.isUpdate || Trigger.isDelete) {
		for (PurchaseLine__c line : Trigger.old) {
			if (line.PurchaseId__c != null) {
				purchaseIds.add(line.PurchaseId__c);
			}
		}
	}

	if (!purchaseIds.isEmpty()) {
		PurchaseLineHandler.recalculatePurchases(purchaseIds);
	}
}