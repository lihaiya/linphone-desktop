import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQml.Models
import QtQuick.Controls.Basic as Control
import Linphone
import EnumsToStringCpp 1.0
import UtilsCpp 1.0
import SettingsCpp 1.0
// =============================================================================

Item {
	id: mainItem
	property CallGui call
	property ConferenceGui conference: call && call.core.conference
	property bool callTerminatedByUser: false
	property bool callStarted: call? call.core.isStarted : false
	readonly property var callState: call?.core.state
	property int conferenceLayout: call ? call.core.conferenceVideoLayout : LinphoneEnums.ConferenceLayout.ActiveSpeaker
	property int participantDeviceCount: conference ? conference.core.participantDeviceCount : -1
	onParticipantDeviceCountChanged: {
		setConferenceLayout()
	}
	Component.onCompleted: setConferenceLayout()
	onConferenceLayoutChanged: {
		console.log("CallLayout change : " +conferenceLayout)
		setConferenceLayout()
	}

	Connections {
		target: mainItem.conference? mainItem.conference.core : null
		function onIsScreenSharingEnabledChanged() {
			setConferenceLayout()
		}
	}

	function setConferenceLayout() {
		callLayout.sourceComponent = undefined	// unload old view before opening the new view to avoid conflicts in Video UI.
		callLayout.sourceComponent = conference
			? conference.core.isScreenSharingEnabled || (mainItem.conferenceLayout == LinphoneEnums.ConferenceLayout.ActiveSpeaker && participantDeviceCount > 1)
				? activeSpeakerComponent
				: participantDeviceCount <= 1
					? waitingForOthersComponent
					: gridComponent
			: activeSpeakerComponent
	}

	Text {
		id: callTerminatedText
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		anchors.topMargin: 25 * DefaultStyle.dp
		z: 1
		visible: mainItem.callState === LinphoneEnums.CallState.End || mainItem.callState === LinphoneEnums.CallState.Error || mainItem.callState === LinphoneEnums.CallState.Released
		text: mainItem.conference
				? qsTr("Vous avez quitté la conférence")
				: mainItem.callTerminatedByUser
					? qsTr("Vous avez terminé l'appel") 
					: mainItem.callStarted 
						? qsTr("Votre correspondant a terminé l'appel")
						: call && call.core.lastErrorMessage || ""
		color: DefaultStyle.grey_0
		font {
			pixelSize: 22 * DefaultStyle.dp
			weight: 300 * DefaultStyle.dp
		}
	}
	
	Loader{
		id: callLayout
		anchors.fill: parent
		sourceComponent: mainItem.participantDeviceCount === 0
			? waitingForOthersComponent
			: activeSpeakerComponent
	}

	Component {
		id: waitingForOthersComponent
		Rectangle {
			color: DefaultStyle.grey_600
			radius: 15 * DefaultStyle.dp
			ColumnLayout {
				anchors.centerIn: parent
				spacing: 22 * DefaultStyle.dp
				width: waitText.implicitWidth
				Text {
					id: waitText
					text: qsTr("Waiting for other participants...")
					Layout.preferredHeight: 67 * DefaultStyle.dp
					Layout.alignment: Qt.AlignHCenter
					horizontalAlignment: Text.AlignHCenter
					color: DefaultStyle.grey_0
					font {
						pixelSize: 30 * DefaultStyle.dp
						weight: 300 * DefaultStyle.dp
					}
				}
				Item {
					Layout.fillWidth: true
					Button {
						color: "transparent"
						borderColor: DefaultStyle.main2_400
						icon.source: AppIcons.shareNetwork
						contentImageColor: DefaultStyle.main2_400
						text: qsTr("Share invitation")
						topPadding: 11 * DefaultStyle.dp
						bottomPadding: 11 * DefaultStyle.dp
						leftPadding: 20 * DefaultStyle.dp
						rightPadding: 20 * DefaultStyle.dp
						anchors.centerIn: parent
						textColor: DefaultStyle.main2_400
						onClicked: {
							if (mainItem.conference) {
								UtilsCpp.copyToClipboard(mainItem.call.core.remoteAddress)
								showInformationPopup(qsTr("Copié"), qsTr("Le lien de la réunion a été copié dans le presse-papier"), true)
							}
						}
					}
				}
			}
		}
	}
	
	Component{
		id: activeSpeakerComponent
		ActiveSpeakerLayout{
			Layout.fillWidth: true
			Layout.fillHeight: true
			call: mainItem.call
		}
	}
	Component{
		id: gridComponent
		CallGridLayout{
			Layout.fillWidth: true
			Layout.fillHeight: true
			call: mainItem.call
		}
	}
}
// TODO : waitingForParticipant
		// ColumnLayout {
		// 	id: waitingForParticipant
		// 	Text {
		// 		text: qsTr("Waiting for other participants...")
		// 		color: DefaultStyle.frey_0
		// 		font {
		// 			pixelSize: 30 * DefaultStyle.dp
		// 			weight: 300 * DefaultStyle.dp
		// 		}
		// 	}
		// 	Button {
		// 		inversedColors: true
		// 		text: qsTr("Share invitation")
		// 		icon.source: AppIcons.shareNetwork
		// 		color: DefaultStyle.main2_400
		// 		Layout.preferredWidth: 206 * DefaultStyle.dp
		// 		Layout.preferredHeight: 47 * DefaultStyle.dp
		// 	}
		// }

