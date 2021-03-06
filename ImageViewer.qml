import QtQuick 2.0
import QtQuick.Controls 2.4
import QtQuick.Window 2.11
import QtQuick.Layouts 1.3

ApplicationWindow {
    id: mainImgV
    visible: true
    visibility: "FullScreen"

    width: 1024
    height: 768
    title: qsTr("Poppler plugin example")
    property string sourcePath
    color: "#eee"
    Component.onCompleted: {

        console.log("----> sourcePath "+ sourcePath)
    }
    header: ToolBar {
        leftPadding: 8
        rightPadding: 8
        RowLayout {
            anchors.fill: parent
            spacing: 16

            Button {
                text: qsTr("Précédent ")
                flat: true

                onClicked: mainImgV.close()
            }

            Slider {
                id: zoomSlider

                from: 0.5
                to: 2
                stepSize: .1
                value: 1

                onValueChanged: pdfView.zoom = value
            }

            Item {
                Layout.fillWidth: true
            }

            //            TextField {
            //                id: searchField
            //                placeholderText: qsTr("Search")
            //                Material.theme: Material.Dark

            //                onTextChanged: searchTimer.restart()
            //                Keys.onReturnPressed: {
            //                    searchTimer.stop()
            //                    pdfView.search(searchField.text)
            //                }

            //                Timer {
            //                    id: searchTimer
            //                    interval: 1000
            //                    onTriggered: pdfView.search(searchField.text)
            //                }
            //            }
        }
    }

    Flickable {
        id: flickable
        clip: true
        contentHeight: imageContainer.height
        contentWidth: imageContainer.width
        onHeightChanged: image.calculateSize()
        property alias source: image.source
        property alias status: image.status
        property alias progress: image.progress
        property string remoteSource: ''
        property string localSource: ''
        signal swipeLeft()
        signal swipeRight()
        signal imageClicked();
        Item {
            id: imageContainer
            width: Math.max(image.width * image.scale, flickable.width)
            height: Math.max(image.height * image.scale, flickable.height)
            AnimatedImage {
                id: image
                property real prevScale
                smooth: !flickable.movingVertically
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                cache: false
                function calculateSize() {
                    scale = Math.min(flickable.width / width, flickable.height / height) * 0.98;
                    pinchArea.minScale = scale;
                    prevScale = Math.min(scale, 1);
                }
                onScaleChanged: {
                    if ((width * scale) > flickable.width) {
                        var xoff = (flickable.width / 2 + flickable.contentX) * scale / prevScale;
                        flickable.contentX = xoff - flickable.width / 2;
                    }
                    if ((height * scale) > flickable.height) {
                        var yoff = (flickable.height / 2 + flickable.contentY) * scale / prevScale;
                        flickable.contentY = yoff - flickable.height / 2;
                    }
                    prevScale = scale;
                }
                onStatusChanged: {
                    if (status == Image.Ready) {
                        calculateSize();
                        playing = true
                    } else if (status == Image.Error &&image.source != remoteSource) {
                        image.source = remoteSource
                    }
                }
                //            Behavior on scale {NumberAnimation{duration: 200}}
            }
        }
        PinchArea {
            id: pinchArea
            property real minScale:  1.0
            property real lastScale: 1.0
            anchors.fill: parent
            pinch.target: image
            pinch.minimumScale: minScale
            pinch.maximumScale: 3.0
            onPinchFinished: flickable.returnToBounds()
        }
        MouseArea {
            anchors.fill : parent
            property bool doubleClicked: false
            property bool swipeDone: false
            property int startX
            property int startY
            property real startScale: pinchArea.minScale
            Timer {
                id: clickTimer
                interval: 350
                running: false
                repeat:  false
                onTriggered: {
                    //                if (!parent.swipeDone) {
                    //                    showAlt = !showAlt
                    //                }
                    parent.swipeDone = false
                }
            }
            onDoubleClicked: {
                clickTimer.stop()
                mouse.accepted = true
                if (image.scale > pinchArea.minScale) {
                    image.scale = pinchArea.minScale
                    flickable.returnToBounds()
                } else {
                    image.scale = 2.0
                }
            }
            onClicked: {
                // There's a bug in Qt Components emitting a clicked signal
                // when a double click is done.
                clickTimer.start()
                imageClicked();
            }
            onPressed: {
                startX = (mouse.x / image.scale)
                startY = (mouse.y / image.scale)
                startScale = image.scale
            }
            onReleased: {
                if (image.scale === startScale) {
                    var deltaX = (mouse.x / image.scale) - startX
                    var deltaY = (mouse.y / image.scale) - startY
                    // Swipe is only allowed when we're not zoomed in
                    if (image.scale == pinchArea.minScale &&
                            (Math.abs(deltaX) > 50 || Math.abs(deltaY) > 50)) {
                        swipeDone = true
                        if (deltaX > 30) {
                            flickable.swipeRight()
                        } else if (deltaX < -30) {
                            flickable.swipeLeft()
                        }
                    }
                }
            }
        }
    }
}
