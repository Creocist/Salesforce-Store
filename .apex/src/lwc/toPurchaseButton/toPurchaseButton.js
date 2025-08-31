import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class GoToShopButton extends NavigationMixin(LightningElement) {
    @api recordId;

    handleClick() {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Purchase_Page1'
            },
            state: {
                c__accountId: this.recordId
            }
        });
    }

}
