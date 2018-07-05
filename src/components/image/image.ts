import { Component } from '@angular/core';
import { NavController, LoadingController, ViewController, ToastController, NavParams, Loading, AlertController} from 'ionic-angular';
import { InAppBrowser } from '@ionic-native/in-app-browser';
import { HttpProvider } from '../../providers/http/http';
@Component({ 
  selector: 'image',
  templateUrl: 'image.html'
})
export class ImageComponent {

  url: string;
  loading : Loading;
  constructor( 
    public navParams: NavParams, 
    public viewCtrl: ViewController, 
    private iab: InAppBrowser,  
    public httpProvider: HttpProvider,
    public toaster: ToastController,
    private loadingCtrl: LoadingController ,
  ) {

    this.url = this.navParams.get('url');
  }

  dismiss(){
    this.viewCtrl.dismiss({
      url: ''
    });
  }

  openBrowser(url){
    const browser = this.iab.create(url);
  }

  showLoading(text) {
    this.loading = this.loadingCtrl.create({
      content: text,
      dismissOnPageChange: true,
      showBackdrop: false 
    });
    this.loading.present();
  }

  private presentToast(text) {    
    let toast = this.toaster.create({
        message: text,
        duration: 3000,
        position: 'top'
    });
    toast.present();
  }
}
