@IsTest
private class itemClassTest {
	private static void createTestData() {
		List<Item__c> items = new List<Item__c>();
		items.add(new Item__c(
				Name = 'Pizza',
				Description__c = 'A classic from Italy',
				Price__c = 15,
				Type__c = 'Hot',
				Family__c = 'Meat',
				Image__c = ' '
		));
		items.add(new Item__c(
				Name = 'Lemonade',
				Description__c = 'A refreshing drink',
				Price__c = 10,
				Type__c = 'Drink',
				Family__c = 'Vegetarian',
				Image__c = ' '
		));
		insert items;
	}

	@IsTest
	static void testSearchItems_AllItems() {
		createTestData();

		Test.startTest();
		List<Item__c> results = ItemClass.searchItems(null, null, null, 10, 0);
		Test.stopTest();

		System.assertEquals(2, results.size(), 'All data should return');
	}

	@IsTest
	static void testSearchItems_FilterByType() {
		createTestData();

		List<String> types = new List<String>{ 'Hot' };

		Test.startTest();
		List<Item__c> results = ItemClass.searchItems(types, null, null, 10, 0);
		Test.stopTest();

		System.assertEquals(1, results.size(), 'Should return 1 item');
		System.assertEquals('Pizza', results[0].Name);
	}
	@IsTest
	static void testSearchItems_FilterByFamily() {
		createTestData();

		List<String> family = new List<String>{ 'Meat' };

		Test.startTest();
		List<Item__c> results = ItemClass.searchItems(null, family, null, 10, 0);
		Test.stopTest();

		System.assertEquals(1, results.size(), 'Should return 1 item');
		System.assertEquals('Pizza', results[0].Name);
	}

	@IsTest
	static void testSearchItems_SearchKey() {
		createTestData();

		Test.startTest();
		List<Item__c> results = ItemClass.searchItems(null, null, 'Lemonade', 10, 0);
		Test.stopTest();

		System.assertEquals(1, results.size(), 'Search for name, should return Lemonade');
		System.assertEquals('Lemonade', results[0].Name);
	}

	@IsTest
	static void testSearchItems_WithLimitsAndOffset() {
		createTestData();

		Test.startTest();
		List<Item__c> results = ItemClass.searchItems(null, null, null, 1, 0);
		Test.stopTest();

		System.assertEquals(1, results.size(), 'With limit=1 only 1 item will return');
	}
}
