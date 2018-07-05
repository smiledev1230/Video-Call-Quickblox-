import { NgModule } from '@angular/core';
import { IonicPageModule } from 'ionic-angular';
import { SearchCountPage } from './search-count';

@NgModule({
  declarations: [
    SearchCountPage,
  ],
  imports: [
    IonicPageModule.forChild(SearchCountPage),
  ],
})
export class SearchCountPageModule {}
