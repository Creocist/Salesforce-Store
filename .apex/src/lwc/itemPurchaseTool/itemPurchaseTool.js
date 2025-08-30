import { LightningElement, track } from 'lwc';
import getItemsByType from '@salesforce/apex/ItemsClass.getItemsByType';

export default class ItemCatalog extends LightningElement {
    @track items = [];
    @track selectedType = '';


    loadItems(type) {
        this.selectedType = type;
        getItemsByType({ typeValue: type })
            .then(result => {
                this.items = result;
            })
            .catch(error => {
                console.error('Error:', error);
                this.items = [];
            });
    }

    handleFilter(event) {
        this.loadItems(event.target.dataset.type);
    }
}