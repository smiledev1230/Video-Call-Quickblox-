import { Component } from '@angular/core';
import { IonicPage, AlertController, NavController, Loading, LoadingController, NavParams } from 'ionic-angular';
import { HomePage } from '../home/home';
import { Storage } from '@ionic/storage';
// import { Facebook, FacebookLoginResponse } from '@ionic-native/facebook';

@Component({
  selector: 'page-login',
  templateUrl: 'login.html',
})
export class LoginPage {

  public logo_src = "assets/logo_red.png";
  public loading: Loading;  
  public isChecked: any; 
  constructor(
    public navCtrl: NavController, 
    public navParams: NavParams,
    public loadingCtrl: LoadingController,
    private storage: Storage,
    // private fb: Facebook,    
    private alertCtrl: AlertController,
  ) 
  {
      this.storage.get('user_auth').then(
      data =>{          
        console.log(data);                 
        if(data != null)         
          this.isChecked = true;
        if(data == null)   
          this.isChecked = false;    
      }
    );  
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad LoginPage');
  }

  loginWithFacebook(){   
    this.showLoading('');
  }

  showAlert(text) {      
    let alert = this.alertCtrl.create({
      title: 'Warning!',
      subTitle: text,
      buttons: [{
        text: "OK",
      }]
    });
    alert.present();
  }

  checkRemember(event){  
    if(event.checked == true){
      this.storage.set('user_auth', true);      
    }
    if(event.checked == false){
      this.storage.remove('user_auth');
    }
  }

  showLoading(text) {
    this.loading = this.loadingCtrl.create({
      content: text,
      dismissOnPageChange: true,
      showBackdrop: false 
    });
    this.loading.present();
  }
}
