import { Injectable } from '@angular/core';
import { Platform, AlertController, Events } from 'ionic-angular';
import { Http, Headers } from '@angular/http';
import 'rxjs/add/operator/map';
import 'rxjs/add/operator/do';
import { Contacts, Contact, ContactField } from '@ionic-native/contacts';
import { ToastController } from 'ionic-angular';
import { SplashScreen } from '@ionic-native/splash-screen';
import { DomSanitizer } from '@angular/platform-browser';

@Injectable()export class DataProvider {
  
  // ==============
  public playerID = null;
  public iosStyle = "";
  public firstLoad = true;
  public missing_contacts = 0;
  public accounts_list = [];
  public forwardText = '';
  public curuser: any;
  public pageState: any;
  public pageStateId: any;

  public messages: any;
  public messagesToShow: any;
  public startIndex: any;
  
  public defaultLang = 'en'; // language
  public userLocation: any;

  // QB variables for calling
  public callType: any;
  public videoCallSession: any;
  public mediaParams = {
    audio: true,
		video: true,
		options: {
			muted: true,
			mirror: false
    }
  };
  public userData:any;
  public usersData:any[] = [];
  public onVideCall:boolean = false;
  public onAudioCall:boolean = false;
  public callingStatus:boolean = false;
  public reCall:boolean = false;
  public conversation: any = {
    key: 'FKvXQGUpB1dzZm6T81cIGbhwx8h1',
    type: "call-video"
  }
  public userList: any = []; waste;

  constructor(public platform: Platform, public http: Http, public contacts: Contacts, public alertCtrl: AlertController, public events:Events, private toastCtrl: ToastController, public splashScreen: SplashScreen, public sanitizer: DomSanitizer) {
  
    console.log("Initializing Data Provider");
  }
 }