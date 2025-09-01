@IsTest
private class ItemImageTest {
	@IsTest
	static void TestImages(){
		Item__c it1 = new Item__c(Name='B1', Price__c = 10, Description__c ='Something');
		Item__c it2 = new Item__c(Name='B2', Price__c = 20, Description__c ='Something');
		insert new List<Item__c>{ it1, it2 };
		UnsplashService.fakeUrl = 'https://test.com/fake.jpg';


		Test.startTest();
		GetImageItem.ItemsWithImages();
		Test.stopTest();
		Item__c It = [SELECT Id, Image__c FROM Item__c WHERE Name='B1'];
		System.assertEquals('https://test.com/fake.jpg',It.Image__c);
	}
}
