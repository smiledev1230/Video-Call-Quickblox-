import { Component, ViewChild } from '@angular/core';
import { Nav, MenuController, Platform } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';
import { Storage } from '@ionic/storage';

import { HomePage } from '../pages/home/home';
import { ListPage } from '../pages/list/list';
import { LoginPage } from '../pages/login/login';
import { DataProvider } from '../providers/data/data';
import { PercentagePage } from '../pages/percentage/percentage';
declare var cordova;

@Component({
  templateUrl: 'app.html'
})
export class MyApp {
  @ViewChild(Nav) nav: Nav;

  rootPage: any = PercentagePage;

  pages: Array<{title: string, component: any}>;

  constructor(
    public platform: Platform, 
    public statusBar: StatusBar, 
    public splashScreen: SplashScreen,
    public menu: MenuController,
    private storage: Storage,
    public dataProvider: DataProvider,
  ) {
    this.initializeApp();
  }

  initializeApp() {
    this.platform.ready().then(() => {
   
      if (this.platform.is('ios')) {
        cordova.plugins.barcodeScanner.initQB();
        cordova.plugins.iosrtc.registerGlobals();
        this.dataProvider.iosStyle = "ioss";
      }

      var loadScriptAsync = function (path) {
        var jsScript = document.createElement("script");
        jsScript.type = "text/javascript";
        jsScript.async = false;
        jsScript.src = path;
        document.getElementsByTagName("body")[0].appendChild(jsScript);
      }
      loadScriptAsync("assets/js/quickblox.min.js");

      this.statusBar.styleDefault();
      this.splashScreen.hide();
     
      // === ios rtc ===
      var tt = this;
      var updatedVideoFrames = function () {
        if (tt.platform.is("ios")) {
          cordova.plugins.iosrtc.refreshVideos();
        }
      }

      document.addEventListener('orientationchange', updatedVideoFrames);
      document.addEventListener('scroll', updatedVideoFrames);
    });
  }

  openPage(page) {
    this.menu.close();
    if(page == 'App Setting')
    {        
        this.nav.push(ListPage);
    }
    else if(page == 'Log out')
    {
        this.nav.setRoot(LoginPage);
    }
  }
}
