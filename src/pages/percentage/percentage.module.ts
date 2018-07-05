import { NgModule } from '@angular/core';
import { IonicPageModule } from 'ionic-angular';
import { PercentagePage } from './percentage';

@NgModule({
  declarations: [
    PercentagePage,
  ],
  imports: [
    IonicPageModule.forChild(PercentagePage),
  ],
})
export class PercentagePageModule {}
