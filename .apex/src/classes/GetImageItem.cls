public class GetImageItem {
	@AuraEnabled
	public static void ItemsWithImages() {
		List<Item__c> itemsToUpdate = [SELECT Id, Name, Image__c FROM Item__c WHERE Image__c = NULL];

		List<Item__c> updatedItems = new List<Item__c>();

		for (Item__c it : itemsToUpdate) {
			String imageUrl = UnsplashService.getImageUrl(it.Name);

			if (imageUrl != null) {
				it.Image__c = imageUrl;
				updatedItems.add(it);
			}
		}
		if (!updatedItems.isEmpty()) {
			update updatedItems;
		}
	}
}