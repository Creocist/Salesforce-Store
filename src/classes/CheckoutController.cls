public with sharing class CheckoutController {
	public static Id checkoutCart(List<CartItemWrapper> items) {
		if (items == null || items.isEmpty()) {
			throw new AuraHandledException('Cart is empty.');
		}

		// 1. Создаем новый Purchase
		Purchase__c purchase = new Purchase__c(
				Name = 'Purchase ' + Date.today()
		);
		insert purchase;

		// 2. Создаем PurchaseLine для каждого товара
		List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
		for (CartItemWrapper item : items) {
			PurchaseLine__c line = new PurchaseLine__c(
					Purchase__c = purchase.Id,
					Quantity__c = item.quantity,
					Price__c = item.price,
					LineTotal__c = item.quantity * item.price
			);
			lines.add(line);
		}
		insert lines;

		return purchase.Id;
	}
	public class CartItemWrapper {
		@AuraEnabled public String productId;
		@AuraEnabled public Integer quantity;
		@AuraEnabled public Decimal price;
	}
}