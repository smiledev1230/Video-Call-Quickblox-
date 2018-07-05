import { Component } from '@angular/core';
import { IonicPage, AlertController, NavController, App, Events, Platform, ModalController, NavParams, ToastController } from 'ionic-angular';
import { HomePage } from '../../pages/home/home';
import { DataProvider } from '../../providers/data/data';
import { AcceptPage } from '../../pages/accept/accept';
import { Diagnostic } from '@ionic-native/diagnostic';
import { Camera, CameraOptions } from '@ionic-native/camera';
declare var QB;
declare var cordova;
@Component({
  selector: 'page-percentage',
  templateUrl: 'percentage.html',
})
export class PercentagePage {

  public modal: any;
  private SESSION_TOKEN: any;
  private isLogged: boolean = false;
  // private appUserId: any = '1';
  private appUserId: any = '2';
  public user: any = {
    qb: 48261350, 
    qbinfo : {
        created_at: "2018-04-24T09:31:49Z",
        id: 48261350,
        last_request_at: "2018-04-24T09:47:27Z",
        login: '1',
        owner_id: 95277,
        updated_at: "2018-04-24T09:47:27Z"        
    }
  }
  // public user: any = {
  //   qb: 48276578, 
  //   qbinfo : {
  //       created_at: "2018-04-24T09:31:49Z",
  //       id: 48276578,
  //       last_request_at: "2018-04-24T09:47:27Z",
  //       login: '2',
  //       owner_id: 95277,
  //       updated_at: "2018-04-24T09:47:27Z"        
  //   }
  // }  
  public CONFIG = {
      chatProtocol: {
        active: 2 // set 1 to use BOSH, set 2 to use WebSockets (default)
      },
      on: {
        sessionExpired: (value) => {
          console.log("sessionExpired", value())
        }
      },
      webrtc: {
        answerTimeInterval: 60, // Max answer time after that the 'QB.webrtc.onUserNotAnswerListener' callback will be fired.
        dialingTimeInterval: 5,  // The interval between call requests produced by session.call(extension)
        disconnectTimeInterval: 60, // If an opponent lost a connection then after this time the caller will now about it via 'QB.webrtc.onSessionConnectionStateChangedListener' callback.
        statsReportTimeInterval: true, // Allows access to the statistical information about a peer connection. You can set amount of seconds you can get statistic information after.
        iceServers: [
          {
            'url': 'stun:stun.l.google.com:19302'
          },
          {
            'url': 'stun:turn.quickblox.com',
            'username': 'quickblox',
            'credential': 'baccb97ba2d92d71e26eb9886da5f1e0'
          },
          {
            'url': 'turn:turn.quickblox.com:3478?transport=udp',
            'username': 'quickblox',
            'credential': 'baccb97ba2d92d71e26eb9886da5f1e0'
          },
          {
            'url': 'turn:turn.quickblox.com:3478?transport=tcp',
            'username': 'quickblox',
            'credential': 'baccb97ba2d92d71e26eb9886da5f1e0'
          }]
      },
      debug: { mode: 1 } // set DEBUG mode
  };

  constructor(
    public navCtrl: NavController, 
    public navParams: NavParams,
    public app: App,
    public plt: Platform,
    public modalCtrl: ModalController,
    public dataProvider: DataProvider,
    public events: Events,
    public diagnostic: Diagnostic,
    public alertCtrl: AlertController,
    private camera: Camera,
    public toastCtrl: ToastController
  ) 
  {
    var CREDENTIALS = {
      appId: 70298,
      authKey: 'sCFz8fZMrbyJks9',
      authSecret: 'dHJ74G5X4tVay65',
      accountKey: 'kpc5VT5x7Ck4C4s2647M'
    };     
    
    setTimeout(() => {
      this.plt.ready().then(() => {
       
        // const options: CameraOptions = {
        //   quality: 100,
        //   destinationType: this.camera.DestinationType.DATA_URL,
        //   encodingType: this.camera.EncodingType.JPEG,
        //   mediaType: this.camera.MediaType.PICTURE
        // } 

        // this.camera.getPicture(options).then((imageData) => {
        //  let base64Image = 'data:image/jpeg;base64,' + imageData;
        // }, (err) => {
        //  // Handle error
        // });

        if (QB) {
          QB.init(CREDENTIALS.appId, CREDENTIALS.authKey, CREDENTIALS.authSecret, this.CONFIG);       
          this.loginQuickblox();
        }
        // if (this.plt.is('ios')) {
        //   this.checkCall();
        // }
      });
    }, 1000);

    this.events.subscribe("change:call", (id) => { console.log("XXX=====change:call");
      this.dataProvider.callType = 'voice';
      this.goCall(id, 'audio', true);
    });
    this.events.subscribe("change:call-video", (id) => { console.log("XXX=====change:call-video");
      this.dataProvider.callType = 'video';
      this.goCall(id, 'video', true);
    });

    this.events.subscribe("change:tab", (type, ugid) => {  
      if(type == 'call') {
        this.switchToCall(ugid);
      } else if(type == 'call-video') {
        this.switchToCall(ugid, true);
      } 
    });
  }

  switchToCall(id, isVideo=false) {   
    setTimeout(() => {
      if(isVideo) {
        this.events.publish('change:call-video', id);
      } else {
        this.events.publish('change:call', id);
      }
    }, 500);
  }

  ngOnDestroy() {
    this.events.unsubscribe("change:call", null);
    this.events.unsubscribe("change:call-video", null);
  }

  goCall(id, type, answer=false) {
      console.log("XXX=====goCall");
      if (!this.plt.is('ios')) {
        if (answer && (this.dataProvider.videoCallSession == null || !this.dataProvider.videoCallSession)) {
          return;
        }
      } 

      this.goVideoCall(id, answer);
  }

  checkPermission( videotokPermission: any[] ) {
		return new Promise( resolve => {
			if (1) {
				// Check for permission first
				this.diagnostic.getPermissionsAuthorizationStatus(videotokPermission).then((statuses) => {
					console.log('getPermissionsAuthorizationStatus!!', statuses);

					let reqs:string[] = [];
					for (var permission in statuses){
						if (statuses[permission] != this.diagnostic.permissionStatus.GRANTED) {
							reqs.push(permission)
						}
					}

					if (reqs.length > 0) {
						this.diagnostic.requestRuntimePermissions( reqs ).then((permissioins) => {
							console.log('requestRuntimePermissions!!', permissioins, this.diagnostic.permissionStatus.GRANTED);

							reqs = []
							for (var permission in permissioins) {
								console.log('requestRuntimePermissions!!', permission, permissioins[permission]);
								if (permissioins[permission] != this.diagnostic.permissionStatus.GRANTED) {
									reqs.push(permission)
								}
							}
							console.log('requestRuntimePermissions!!', reqs);
							if (reqs.length > 0) {
								let alert = this.alertCtrl.create({
									title: 'Hardware permission!',
									subTitle: 'Hardware permission not available!',
									buttons: ['OK']
								});
								alert.present();
								return
							}
						});
					} else {
						resolve(true)
					}
				});
			} else {
				resolve(true)				
			}
		})	    
  }

  ionViewDidLoad() {
    console.log('ionViewDidLoad PercentagePage');    
    if (this.plt.is('ios')) {
      let tt = this;
      var callback = function(jsonData) { 

        cordova.plugins.barcodeScanner
        .handleCallQB(handleQB)
        .handleEndCallQB(handleEndCallQB)
        .handleAcceptCallQB(handleAcceptCallQB)
        .endInit();
      };

      setTimeout(() => {
        cordova.plugins.barcodeScanner.loginQB(callback, { userId: this.appUserId });
      }, 2000);

      var handleEndCallQB = function(extension) { 
        if (tt.modal) {
          tt.modal.dismiss().catch();
        }
      }
      var handleAcceptCallQB = function(extension) { 
        if (tt.modal) {
          tt.modal.dismiss().catch();
        }
      }
      var handleQB = function(extension) { 
        if (extension.type == 'video') {
          tt.modal = tt.modalCtrl.create(AcceptPage, { name: extension.name , type: 'video', photo: extension.img }, {cssClass:"my-modal"});
          tt.modal.onDidDismiss(data => {
            if (data == '1') {
              tt.events.publish("change:tab", 'call-video', extension.login);
            } else if (data == '0') {           
              cordova.plugins.barcodeScanner.endCallQB();
            }
          });
          tt.modal.present();
        }
      };
    }
  }

  loginQuickblox() {
    var userName = this.appUserId;
    if (QB && userName) {
      let password = userName.replace(' ', '')
      while (password.length < 8) {
        password += password
      }
      let params = {
        'login': userName,
        'password': password,
        'tag': "man"
      };
      console.log("Login", params);

      QB.createSession(params, (err, user) => {

        console.log("Login complete", err, user, QB.chat);
        // this.checkCall();
        
        if (user) {
          this.SESSION_TOKEN = user.token;     
          // success
          this.dataProvider.userData = { user: user, pass: password, user_id: user.user_id };
          this.connectChatServer()
        } else {
          this.isLogged = false;
          this.registerQuickblox();
        }
      });
    }
  }

  registerQuickblox() {
    var userName = this.appUserId;

    if (QB && userName) {
      let password = userName.replace(' ', '')
      while (password.length < 8) {
        password += password
      }
      var params = {
        'login': userName,
        'password': password,
        'tag': "man"
      };

      QB.createSession((err, result) => {
        console.log('HomePage::registerUser.createSession', err, result);

        if (!err) {
          QB.users.create(params, (err1, user) => {
            console.log('HomePage::createUser', err1, user);
            if (user) {
              // success
              this.dataProvider.userData = { user: user, pass: password, user_id: user.user_id };
              this.connectChatServer()
            }
          });
        }
      });
    }
  }

  goVideoCall(userId, answer = false, initCall = false) {    
    let ans = "0";
    if (answer) ans = "1";
    if (this.plt.is('ios')) {       

        cordova.plugins.barcodeScanner.videoCallQB({userId: this.user.qb, login: this.appUserId, name: 'this.curuser.name', img: 'this.curuser.img', name1: 'user.name', img1: 'user.img', answer: ans, type: 'video'});
    } else {
      this.app.getRootNav().push(HomePage, { userId: userId, type: 'video', answer: answer, initCall: initCall  });
    }
  }

  connectChatServer() {
    console.log("::connectChatServer", this.dataProvider.userData);
    var userId = this.dataProvider.userData.user.user_id ? this.dataProvider.userData.user.user_id : this.dataProvider.userData.user.id

    QB.chat.connect({
      'userId': userId,
      'password': this.dataProvider.userData.pass
      // 'password': (pass)?pass:this.userData.user.token
    }, (err1, roster) => {

      console.log("::chat.connect", err1, roster);
      if (!err1) {
        // success
        this.isLogged = true;
        this.refreshUserList();
      } else {
        this.isLogged = false;
      }
    });
  }

  refreshUserList(){
		console.log('HomePage::refreshUserList');
		if (this.isLogged && QB) {
			var params = { page: '1', per_page: '100'}

			QB.users.listUsers(params, (err, users)=>{
				console.log("chat.listUsers", err, users)
				if (users) {
          this.dataProvider.userList = users.items;       
				}
      });	
      
      this.handleQBWebRtc();
		}
  }

  checkCall() {
    let modal = null;  
      if (this.dataProvider.conversation) {
        if (this.dataProvider.conversation.type && this.dataProvider.conversation.type == 'call-video') {       
            modal = this.modalCtrl.create(AcceptPage, { text: "I am" + " calling..." });
            modal.onDidDismiss(data => {
              if (data == '1') {
                this.events.publish("change:tab", 'call-video', this.dataProvider.conversation.key);
              } else if (data == '0') {
                // this.dataProvider.updateCallType(this.appUserId, conversation.$key, 'ignore');
                // this.dataProvider.updateCallType(conversation.$key, this.appUserId, 'ignore');
              }
            });
            modal.present();
        } else if (this.dataProvider.conversation.type && (this.dataProvider.conversation.type == 'end' || this.dataProvider.conversation.type == 'end-video')) {
          if (modal) {
            modal.dismiss().catch();
          }
        }
      }   
  }

  acceptMediaCall() {
    if (this.plt.is('ios')) {

    } else {
      setTimeout(() => {
        this.dataProvider.pageState = 'calling'
        let mediaParams = {
          audio: true,
          video: true,
          options: {
              muted: true,
              mirror: true
          }, 
          elemId : 'localVideo'
        }
        if (this.plt.is('ios') || this.plt.is('android')) {
          let videotokPermission = [this.diagnostic.permission.RECORD_AUDIO]
          videotokPermission.push(this.diagnostic.permission.CAMERA);
          
          this.checkPermission( videotokPermission ).then( permission => {
            if ( permission ) {
              this.dataProvider.videoCallSession.getUserMedia(mediaParams, (err, stream) => {
                console.log(this.dataProvider.mediaParams, err, stream);
                this.dataProvider.callingStatus = false
                if (err) {
                } else {
                  // if (this.dataProvider.videoCallSession.callType == QB.webrtc.CallType.VIDEO) {
                  //   this.dataProvider.videoCallSession.attachMediaStream('localVideo', stream);
                  // }
                  this.dataProvider.videoCallSession.accept({});
                }
              });
            }
          })
        } else {
          this.dataProvider.videoCallSession.getUserMedia(mediaParams, (err, stream) => {
            console.log(this.dataProvider.mediaParams, err, stream);
            this.dataProvider.callingStatus = false
            if (err) {
            } else {
              this.dataProvider.videoCallSession.accept({});
            }
          });
        }
        
      }, 2000);
    }
  }

  handleQBWebRtc() {
   
    QB.webrtc.onCallListener = (session, extension) => {
      console.log("=====XXX===onCallListener", session, extension);
      this.dataProvider.videoCallSession = session
      if (this.dataProvider.videoCallSession.callType == QB.webrtc.CallType.VIDEO) {
        this.dataProvider.onVideCall = true
      } else {
        this.dataProvider.onAudioCall = true
      }

      session.onSessionCloseListener = () => {
        this.dataProvider.callingStatus = false
        this.dataProvider.onVideCall = false
        this.dataProvider.onAudioCall = false
      }

      session.onSessionConnectionStateChangedListener = (session, userID, connectionState) => {
        console.log("MyApp::webrtc.onSessionConnectionStateChangedListener", session, userID, connectionState)
      }      

      this.dataProvider.callType = extension.type;

      if (extension['recall'] == "1") {
        this.acceptMediaCall();
        return;
      } 

      this.modal = this.modalCtrl.create(AcceptPage, { text: this.appUserId + " video calling..." });
      this.modal.onDidDismiss(data => {
        if (data == '1') {
          this.events.publish("change:tab", 'call-video', this.dataProvider.conversation.key);
          this.acceptMediaCall();
        } else {            
          if(this.dataProvider.videoCallSession)
            this.dataProvider.videoCallSession.stop({recall: "0"})
        }
      });
      this.modal.present();   
    }

    QB.webrtc.onUserNotAnswerListener = (session, userId) => {
      console.log("XXX===onUserNotAnswerListener");
      this.dataProvider.callingStatus = false
      alert("No Answer");
      this.events.publish("call:end");
    };

    QB.webrtc.onAcceptCallListener = (session, userId, extension) => {
      console.log("XXX===onAcceptCallListener");
      this.dataProvider.callingStatus = false;
      this.events.publish("call:connected");
    };

    QB.webrtc.onRejectCallListener = (session, userId, extension) => {
      this.toastCtrl.create({
        message: 'Call is busy...',
        duration: 5000,
        position: 'top'
      }).present();
      console.log("XXX===onRejectCallListener");
      this.dataProvider.callingStatus = false;
      this.events.publish('call:end');
      if (this.modal) {
        this.modal.dismiss().catch();
      }
    };

    QB.webrtc.onStopCallListener = (session, userId, extension) => {
      console.log("XXX===onStopCallListener");
      this.dataProvider.callingStatus = false
      this.dataProvider.onVideCall = false
      this.dataProvider.onAudioCall = false

      this.dataProvider.reCall = false;
      try {
        if (extension['recall'] == "1" || extension['0'] == "1") {
          this.dataProvider.reCall = true;
        } 
      } catch (err) {
        console.log(err);
      }
      this.events.publish('call:end');
      if (this.modal) {
        this.modal.dismiss().catch();
      }
    };

    QB.webrtc.onRemoteStreamListener = (session, userID, remoteStream) => {
      this.dataProvider.callingStatus = false
      // attach the remote stream to DOM element
      if (this.dataProvider.videoCallSession.callType == QB.webrtc.CallType.AUDIO) {
        this.dataProvider.mediaParams.video = false
        this.dataProvider.onAudioCall = true

        session.attachMediaStream('mainAudio', remoteStream);
      } else {
        this.dataProvider.onAudioCall = false
        this.dataProvider.onVideCall = true
        session.attachMediaStream('mainVideo', remoteStream);
      }
      this.dataProvider.pageState = 'calling'
    }

    QB.webrtc.onSessionConnectionStateChangedListener = (session, userID, connectionState) => {

      if (connectionState == QB.webrtc.SessionConnectionState.CLOSED
        || connectionState == QB.webrtc.SessionConnectionState.DISCONNECTED
        || connectionState == QB.webrtc.SessionConnectionState.COMPLETED
      ) {

        console.log("states ", connectionState, QB.webrtc.SessionConnectionState.DISCONNECTED,
          QB.webrtc.SessionConnectionState.CLOSED,
          QB.webrtc.SessionConnectionState.COMPLETED
        )

        this.dataProvider.pageState = 'stopped'
        this.dataProvider.callingStatus = false
        this.dataProvider.onVideCall = false
        this.dataProvider.onAudioCall = false
        if (connectionState == QB.webrtc.SessionConnectionState.CLOSED) {
          
        }

      } else if (connectionState == QB.webrtc.SessionConnectionState.CONNECTED) {
        console.log("=================XXX======== session connected");
      }
    }
  }
}
