public with sharing class ItemsClass {
    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItemsByType(String typeValue) {
        return [
                SELECT Id, Name, Description__c, Price__c, Type__c, Family__c, Image__c
                FROM Item__c
                WHERE Type__c = :typeValue
                ORDER BY Name
        ];
    }
}