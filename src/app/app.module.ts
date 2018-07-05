import { BrowserModule } from '@angular/platform-browser';
import { ErrorHandler, NgModule } from '@angular/core';
import { IonicApp, IonicErrorHandler, IonicModule } from 'ionic-angular';

import { MyApp } from './app.component';
import { HomePage } from '../pages/home/home';
import { ListPage } from '../pages/list/list';
import { ImageComponent } from '../components/image/image';
import { LoginPage } from '../pages/login/login';
import { PercentagePage } from '../pages/percentage/percentage';
import { AcceptPage } from '../pages/accept/accept';
import { NgCircleProgressModule } from 'ng-circle-progress';

import { IonicStorageModule } from '@ionic/storage';
import { StatusBar } from '@ionic-native/status-bar';
import { SplashScreen } from '@ionic-native/splash-screen';
import { HttpProvider } from '../providers/http/http';
import { FileTransfer, FileUploadOptions, FileTransferObject } from '@ionic-native/file-transfer';
import { File } from '@ionic-native/file';
import { FilePath } from '@ionic-native/file-path';
import { Camera, CameraOptions } from '@ionic-native/camera';
import { InAppBrowser } from '@ionic-native/in-app-browser';
import { HttpModule } from '@angular/http';
import { Crop } from '@ionic-native/crop';
import { DataProvider } from '../providers/data/data';
import { Diagnostic } from '@ionic-native/diagnostic';
import { Contacts, Contact, ContactField } from '@ionic-native/contacts';

@NgModule({
  declarations: [
    MyApp,
    HomePage,
    ListPage,
    LoginPage,
    PercentagePage,
    AcceptPage,
    ImageComponent
  ],
  imports: [
    BrowserModule,
    IonicModule.forRoot(MyApp),
    IonicStorageModule.forRoot(),
    HttpModule,
    NgCircleProgressModule.forRoot({
      radius: 100,
      outerStrokeWidth: 16,
      innerStrokeWidth: 8,
      outerStrokeColor: "#78C000",
      innerStrokeColor: "#C7E596",
      animationDuration: 300
    })
  ],
  bootstrap: [IonicApp],
  entryComponents: [
    MyApp,
    HomePage,
    ListPage,
    LoginPage,
    PercentagePage,
    AcceptPage,
    ImageComponent
  ],
  providers: [
    StatusBar,
    SplashScreen,
    {provide: ErrorHandler, useClass: IonicErrorHandler},
    HttpProvider,
    FileTransfer, 
    File,
    FilePath,
    Camera,
    InAppBrowser,
    Crop,
    DataProvider,
    Diagnostic,
    Contacts
  ]
})
export class AppModule {}
