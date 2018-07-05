import { Component, ViewChild } from '@angular/core';
import { Nav, MenuController, Platform } from 'ionic-angular';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';

import { HomePage } from '../pages/home/home';
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
    private storage: Storage
  ) {
    this.initializeApp();
  }

  initializeApp() {
    this.platform.ready().then(() => {
      
      // QB library import
      var loadScriptAsync = function (path) {
        var jsScript = document.createElement("script");
        jsScript.type = "text/javascript";
        jsScript.async = false;
        jsScript.src = path;
        document.getElementsByTagName("body")[0].appendChild(jsScript);
      }
      loadScriptAsync("assets/js/quickblox.min.js");

      // if (this.platform.is('ios')) {
      //   cordova.plugins.barcodeScanner.initQB();
      //   cordova.plugins.iosrtc.registerGlobals();
      //   this.dataProvider.iosStyle = "ioss";
      // }

      this.statusBar.styleDefault();
      this.splashScreen.hide();
    });
  }
}
