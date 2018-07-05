import { Component } from '@angular/core';
import { NavController, NavParams, ViewController } from 'ionic-angular';

@Component({
  selector: 'page-accept',
  templateUrl: 'accept.html',
})
export class AcceptPage {
    public text = "";
    public ret = '-1';

    constructor(public navCtrl: NavController, public navParams: NavParams, public viewCtrl: ViewController) {
        this.text = navParams.get("text");
    }

    ionViewDidLoad() {

    }

    dismiss() {
        this.viewCtrl.dismiss(this.ret);
    }

    accept() {
        this.ret = '1';
        this.dismiss();
    }

    cancel() {
        this.ret = '0';
        this.dismiss();
    }
}
