public with sharing class altItemController {
	@AuraEnabled(cacheable=true)
	public static List<Item__c> getItems(String typeValue) {
		if (String.isBlank(typeValue) || typeValue == 'All') {
			return [
					SELECT Id, Name, Description__c, Price__c, Type__c, Family__c, Image__c
					FROM Item__c
					ORDER BY Name
			];
		} else {
			return [
					SELECT Id, Name, Description__c, Price__c, Type__c, Family__c, Image__c
					FROM Item__c
					WHERE Type__c = :typeValue
					ORDER BY Name
			];
		}
	}
}