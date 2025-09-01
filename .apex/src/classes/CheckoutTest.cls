@IsTest
private class CheckoutTest {
	@IsTest
	static void testCheckoutCreatesPurchaseAndLines() {
		Account a = new Account(Name='Tst'); insert a;

		Item__c it1 = new Item__c(Name='B1', Price__c = 10, Description__c ='Something');
		Item__c it2 = new Item__c(Name='B2', Price__c = 20, Description__c ='Something');
		insert new List<Item__c>{it1, it2};

		CheckoutController.CartLine cl1 = new CheckoutController.CartLine();
		cl1.itemId = it1.Id; cl1.qty = 2;
		CheckoutController.CartLine cl2 = new CheckoutController.CartLine();
		cl2.itemId = it2.Id; cl2.qty = 1;

		Test.startTest();
		Id purchaseId = CheckoutController.checkout(a.Id, new List<CheckoutController.CartLine>{cl1, cl2});
		Test.stopTest();

		Purchase__c p = [SELECT Id, TotalNumber__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
		System.assertEquals(3, Integer.valueOf(p.TotalNumber__c));
		System.assertEquals( (2*10) + (1*20), p.GrandTotal__c );
	}

}