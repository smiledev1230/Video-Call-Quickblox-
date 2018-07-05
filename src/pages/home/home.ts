import { Component } from '@angular/core';
import { NavController, NavParams, App, Events, ViewController, AlertController, Platform } from 'ionic-angular';
import { DataProvider } from '../../providers/data/data';
import { Diagnostic } from '@ionic-native/diagnostic';
declare var QB;
@Component({
    selector: 'page-calling',
    templateUrl: 'home.html'
})
export class HomePage {
    public callType: any;
    public duration: any;
    public userId: any;
    public playerId: any;
    public devices: any = [];
    public currentDevice = 0;
    public curuser: any = {
        // userId: 48261350,
        userId: 48276578,      
    };

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
    //     qb: 48276578, 
    //     qbinfo : {
    //         created_at: "2018-04-24T09:31:49Z",
    //         id: 48276578,
    //         last_request_at: "2018-04-24T09:47:27Z",
    //         login: '2',
    //         owner_id: 95277,
    //         updated_at: "2018-04-24T09:47:27Z"        
    //     }
    // }    
    
    public curUserName = "";
    private conversationId: any = '1';
    private appUserId: any;
    private timer: any;
    private timer1: any;
    private time: any;
    private isAnswer = false;
    private occupantDetails: any;
    public type = "video";
    public qbinfo: any;
    private isEndButton = false;
    public typeEnd = "";
    // button options
    public isMute = false;
    public isVideoMute = false;
    public videoBack = false;
    public init_call = false;
    public mediaStream: any;

    constructor(public navCtrl: NavController, public navParams: NavParams, public diagnostic: Diagnostic, public app: App, public dataProvider: DataProvider, public events: Events, public viewCtrl: ViewController, public alertCtrl: AlertController, public platform: Platform)
    {         
        this.userId = this.navParams.get('userId');
        this.type = this.navParams.get('type');
        this.isAnswer = this.navParams.get('answer');
        if (this.type == 'video') this.typeEnd = '-video';
        this.init_call = this.navParams.get('initCall');
        this.duration = "Calling";

        if (this.dataProvider.conversation) {
            if (this.dataProvider.conversation.type && (this.dataProvider.conversation.type == 'answer' || this.dataProvider.conversation.type == 'answer-video')) {
                this.startTimer();
            }
        }
       
        if( this.user){
            this.qbinfo = this.user.qb;
            this.occupantDetails = this.user.qbinfo;
        }
        
        this.events.subscribe("call:end", () => { console.log("XXX=== event === call:end")
            this.endCall();
            if (!this.dataProvider.reCall) {
                this.back();
            }
        });

        this.events.subscribe("call:connected", () => { console.log("XXX=== event === call:connected")
            if (!this.dataProvider.reCall) {
                this.startTimer();
            }         
            this.init_call = false;
        });
    }

    ionViewDidLoad() {
        this.time = 0;     
        this.initCall();
        this.start();
    }

    startConference(type, item){
		// this.occupantDetails = item.user;
        // this.occupantDetails.full_name;
         
        if ( this.platform.is('ios') || this.platform.is('android')) {
            let videotokPermission = [this.diagnostic.permission.RECORD_AUDIO]
            if (type != 'audio') {
            	videotokPermission.push(this.diagnostic.permission.CAMERA)
            }

            this.checkPermission( videotokPermission ).then( permission => {
            	if ( permission ) {
            		this.startVideoCall([item], (type == 'audio'))
            	}
            })
        } else {       
            this.startVideoCall([item], (type == 'audio'))
        }
    }

    checkPermission( videotokPermission: any[] ) {
		return new Promise( resolve => {
			if (1) {
				// Check for permission first
				this.diagnostic.getPermissionsAuthorizationStatus(videotokPermission).then((statuses) => {
					console.log('getPermissionsAuthorizationStatus!!', statuses);

					let reqs:string[] = []
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
    
    startVideoCall(users, isAudio: boolean = false) {
		console.log("ChatMultimediaPage::startVideoCall", 
            users, this.dataProvider.userData, this.occupantDetails, isAudio);
            
        let calleesIds = users; // User's ids
         console.log(QB.webrtc);
		let sessionType = QB.webrtc.CallType.VIDEO; // AUDIO is also possible
		if (isAudio) {
			sessionType = QB.webrtc.CallType.AUDIO;
			this.dataProvider.mediaParams.video = false
			this.dataProvider.onAudioCall = true
			this.dataProvider.onVideCall = false
		} else {
            this.dataProvider.mediaParams.video = true
			this.dataProvider.onVideCall = true
			this.dataProvider.onAudioCall = false
		}		
      
        let mediaParams;
        if (1 || !isAudio) {
            mediaParams = {
                audio: true,
                video: true,
                options: {
                    muted: true,
                    mirror: true
                }, 
                elemId : 'localVideo'
            }
        } else {
            mediaParams = this.dataProvider.mediaParams;
        }

		this.dataProvider.videoCallSession = QB.webrtc.createNewSession(calleesIds, sessionType);
		this.dataProvider.videoCallSession.getUserMedia(this.dataProvider.mediaParams, (err, stream) => {
			console.log("ChatMultimediaPage::getUserMedia", err, stream);
            this.mediaStream = stream;
			if (err) {
                if (err['name'] == "NotFoundError") {
                    alert(err.message);
                }
                this.endCall();
                this.back();
			} else {				
                this.occupantDetails['name'] = this.curuser.name;
                this.occupantDetails['img'] = this.curuser.img;
                this.dataProvider.pageState = 'calling'

                this.dataProvider.callingStatus = true
                this.dataProvider.videoCallSession.call(this.occupantDetails, (error) =>{
                    if (error) {
                        this.dataProvider.callingStatus = false
                        this.dataProvider.onVideCall = false
                        this.dataProvider.onAudioCall = false
                    }
                });

                var params = {
                    notification_type: 'push',
                    push_type: 'apns_voip',
                    user: {ids: calleesIds}, // recipients.
                    environment: 'development', // environment, can be 'production' as well.
                    message: QB.pushnotifications.base64Encode('MPC calling...')
                };
                QB.pushnotifications.events.create(params, function(err, response) {
                    if (err) {
                        console.log(err);
                    } else {
                        // success
                    }
                });			
			}
		});		
    }
    
    getoccupantDetails(id){
		if (this.dataProvider.usersData[''+id]){
			return this.dataProvider.usersData[''+id];
		}
	}

    startTimer() {
        this.timer = setInterval(() => {
            this.time++;
            this.showDuration();
        }, 1000);

        // setTimeout(() => {
        //     if (this.platform.is('ios') || this.platform.is('android')) {
        //         if (this.type == 'audio') {
        //             AudioToggle.setAudioMode(AudioToggle.EARPIECE);
        //         } else {
        //             AudioToggle.setAudioMode(AudioToggle.SPEAKER);
        //         }
        //     }
        // }, 2000);
    }

    showDuration() {
        var num = this.time;
        var duration = "00: 00";
        if (num < 60) duration = "00: " + this.convNumberWithZero(num);
        else if (num >= 60 && num < 60 * 60) {
            duration = this.convNumberWithZero(Math.floor(num / 60)) + ": " + this.convNumberWithZero(num % 60);
        } else {
            duration = this.convNumberWithZero(Math.floor(num / 60 * 60)) + ": " + this.convNumberWithZero(Math.floor((num % 3600) / 60)) + ": " + this.convNumberWithZero(num % 60);
        }
        this.duration = duration;
    }

    convNumberWithZero(num) {
        if (num * 1 < 10) return "0" + num;
        return num;
    }

    stopVideo(){
        if(this.dataProvider.videoCallSession) {
            this.dataProvider.videoCallSession.stop({recall: "0"})
        }
        this.dataProvider.videoCallSession = null;
	}

    endCall() {
        this.stopVideo();
        if (!this.dataProvider.reCall) {
            // this.dataProvider.updateCallType(this.appUserId, this.userId, 'end'+this.typeEnd);
            // this.dataProvider.updateCallType(this.userId, this.appUserId, 'end'+this.typeEnd);
        }
    }

    ignore() {
        // this.dataProvider.updateCallType(this.appUserId, this.userId, 'ignore'+this.typeEnd);
      
        clearTimeout(this.timer);
        try {
            this.navCtrl.pop();
        } catch (err) {
            console.log(err);
        }
    }

    answer() { 
        // var extension = {};
        // this.dataProvider.videoCallSession.accept(extension);
        // QB.webrtc.onAcceptCallListener = function(session, userId, extension) {
 
        // };
        // this.startConference(this.type, this.qbinfo);
        // this.dataProvider.updateCallType(this.appUserId, this.userId, 'answer'+this.typeEnd);
    }

    initCall() {
        this.isMute = false;

        setTimeout(() => {
            this.isEndButton = true;
        }, 1000);

        if (this.isAnswer) {
            this.startTimer();
            this.answer();
        } else {
            setTimeout(() => {
                this.checkQbInit();
            }, 500)
        }
    }

    checkQbInit() {
        if (this.dataProvider.userList.length > 0) {
            this.startConference(this.type, this.qbinfo);
            this.saveCall();
        } else {
            this.timer1 = setTimeout(() => {
                this.checkQbInit();
            }, 500)
        }
    }

    saveCall() {
        let saveMessage = {
            date: new Date().toString(),
            sender: this.curuser.userId,
            type: 'voice',
            duration: this.time
        }
        if (this.conversationId) {
            this.updateConversation(saveMessage);
        } else {
            var messages = [];
            messages.push(saveMessage);
            var users = [];
            users.push(this.appUserId);
            users.push(this.userId);
        }
        // this.dataProvider.updateCallType(this.appUserId, this.userId, 'wait'+this.typeEnd);
        // this.dataProvider.updateCallType(this.userId, this.appUserId, 'call'+this.typeEnd);
    }

    ngOnDestroy() { 
        console.log("ngOnDestroy --- calling page");
        
        this.events.unsubscribe("call:end", null);
        this.events.unsubscribe("call:connected", null);

        // this.dataProvider.updateCallType(this.appUserId, this.userId, 'end'+this.typeEnd);
        // this.dataProvider.updateCallType(this.userId, this.appUserId, 'end'+this.typeEnd);
    }

    // Update conversation on database.
    updateConversation(saveMessage) {
      
    }

    back() {
        clearTimeout(this.timer);
        clearTimeout(this.timer1);
        try {
            // this.navCtrl.pop();
            this.navCtrl.popToRoot();
        } catch (err) {
            console.log(err);
        }
    }

    boot() {
        return new Promise((resolve, reject) => {
            navigator.mediaDevices.enumerateDevices().then((devices) => {
                this.devices = devices.filter(dev => dev.kind === 'videoinput');
                resolve(this.devices);
            }).catch((err) => {
                reject(err);
            });
        });
    }

    start() {     
        this.boot().then((devices) => {
            console.log('getSupportedDevices');
            console.log(JSON.stringify(devices));
        });
    }  

    reverseCamera() {             
        if (!this.platform.is('android')) {
            return;
        }
        this.videoBack = !this.videoBack;
        let mediaParams;
        if (this.videoBack) {
            mediaParams = {
                audio: true,
                video: {              
                    deviceId:  this.devices[this.currentDevice + 1].deviceId,               
                },
                options: {
                    muted: true,
                    mirror: true
                }, 
                elemId : 'localVideo'
            }
            console.log('back');
            console.log(this.devices[this.currentDevice + 1].deviceId);
        } else {
            mediaParams = {
                audio: true,
                video:  { 
                    deviceId:  this.devices[this.currentDevice].deviceId,
                },
                options: {
                    muted: true,
                    mirror: true
                }, 
                elemId : 'localVideo'
            }
            console.log('front');
            console.log(this.devices[this.currentDevice].deviceId);
        }
        
        let calleesIds = [this.qbinfo]; // User's ids
        let sessionType = QB.webrtc.CallType.VIDEO;
        this.occupantDetails['recall'] = "1";
        
        let userId = this.occupantDetails['userId'];

        if (!this.init_call) {
            if (this.timer) {
                clearInterval(this.timer);
            }
            if(this.dataProvider.videoCallSession) {
                this.dataProvider.videoCallSession.stop({recall: "1"});
            }
            this.dataProvider.videoCallSession = QB.webrtc.createNewSession(calleesIds, sessionType);
        } else {
            this.dataProvider.videoCallSession._closeLocalMediaStream();
        }

        this.dataProvider.videoCallSession.getUserMedia(mediaParams, (err, stream) => {
            console.log("ChatMultimediaPage::getUserMedia", err, stream);
            this.mediaStream = stream;
			if (err) {
                
			} else {    
                if (this.init_call) {
                    let peerConnection = this.dataProvider.videoCallSession.peerConnections[userId];
                    if (peerConnection) {
                        peerConnection.removeStream(peerConnection.getLocalStreams()[0]);
                        peerConnection.addLocalStream(stream);
                        peerConnection.createOffer()
                        .then(function (offer) { console.log(offer);
                            peerConnection.setLocalDescription(offer);
                        })
                        .then(function () {
                            //send(JSON.stringify({ "sdp": peerConnection.localDescription }));
                        });
                    } else {
                        console.log("PeerConnection is null");
                    }
                } else {
                    this.dataProvider.pageState = 'calling'

                    this.dataProvider.callingStatus = true
                    this.dataProvider.videoCallSession.call(this.occupantDetails, (error) =>{
                        if (error) {
                            this.dataProvider.callingStatus = false
                            this.dataProvider.onVideCall = false
                            this.dataProvider.onAudioCall = false
                        }
                    });
                }
			}
		});
    }
    // button functions
    toggleMute() {
        this.isMute = !this.isMute;
        if (this.dataProvider.videoCallSession) {
            if (this.isMute)
                this.dataProvider.videoCallSession.mute('audio');
            else 
                this.dataProvider.videoCallSession.unmute('audio');
        }
    }

    toggleVideoMute() {
        this.isVideoMute = !this.isVideoMute;
        if (this.dataProvider.videoCallSession) {
            if (this.isVideoMute)
                this.dataProvider.videoCallSession.mute('video');
            else 
                this.dataProvider.videoCallSession.unmute('video');
        }
    }
}