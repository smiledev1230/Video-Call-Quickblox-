import { Http, Headers } from '@angular/http';
import { Injectable } from '@angular/core';
import 'rxjs/add/operator/map';
@Injectable()
export class HttpProvider {

  public ADD_API = 'http://autherify.com/api/upload_url.php?';
  contentHeader: Headers = new Headers({"Content-Type": "application/x-www-form-urlencoded"});
  constructor(
    public http : Http,  
  ) 
  {
    console.log('Hello HttpProvider Provider');
  }

  uploadPhotoToServer(photo_name){
    return new Promise(resolve => {
      var param ="search="+photo_name;
      var data = {
        search: photo_name,
      }

      this.http.post(this.ADD_API, JSON.stringify(data), {
        headers: this.contentHeader,
        body: param
      }).map(res => res.json()).subscribe(
        data => {        
          resolve(data);
        },
        err=>{
          resolve('error');
        }
      );
    });
  }
}
