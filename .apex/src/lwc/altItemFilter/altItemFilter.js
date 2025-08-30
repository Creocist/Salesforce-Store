import { LightningElement, track } from 'lwc';
import getItems from '@salesforce/apex/altItemController.getItems';

export default class ItemList extends LightningElement {
    @track items = [];
    @track error;

    connectedCallback() {
        this.loadItems('All'); // загружаем всё при старте
    }

    loadItems(typeValue) {
        getItems({ typeValue })
            .then(result => {
                this.items = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.items = [];
            });
    }

    handleFilter(event) {
        const filterType = event.target.dataset.type;
        this.loadItems(filterType);
    }
}
