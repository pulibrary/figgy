// Annoying, but gotta import every image.
import zoomInRest from 'openseadragon/build/openseadragon/images/zoomin_rest.png'
import zoomInGroup from 'openseadragon/build/openseadragon/images/zoomin_grouphover.png'
import zoomInHover from 'openseadragon/build/openseadragon/images/zoomin_hover.png'
import zoomInDown from 'openseadragon/build/openseadragon/images/zoomin_pressed.png'

import zoomOutRest from 'openseadragon/build/openseadragon/images/zoomout_rest.png'
import zoomOutGroup from 'openseadragon/build/openseadragon/images/zoomout_grouphover.png'
import zoomOutHover from 'openseadragon/build/openseadragon/images/zoomout_hover.png'
import zoomOutDown from 'openseadragon/build/openseadragon/images/zoomout_pressed.png'

import homeRest from 'openseadragon/build/openseadragon/images/home_rest.png'
import homeGroup from 'openseadragon/build/openseadragon/images/home_grouphover.png'
import homeHover from 'openseadragon/build/openseadragon/images/home_hover.png'
import homeDown from 'openseadragon/build/openseadragon/images/home_pressed.png'

import fullPageRest from 'openseadragon/build/openseadragon/images/fullpage_rest.png'
import fullPageGroup from 'openseadragon/build/openseadragon/images/fullpage_grouphover.png'
import fullPageHover from 'openseadragon/build/openseadragon/images/fullpage_hover.png'
import fullPageDown from 'openseadragon/build/openseadragon/images/fullpage_pressed.png'

import rotateLeftRest from 'openseadragon/build/openseadragon/images/rotateleft_rest.png'
import rotateLeftGroup from 'openseadragon/build/openseadragon/images/rotateleft_grouphover.png'
import rotateLeftHover from 'openseadragon/build/openseadragon/images/rotateleft_hover.png'
import rotateLeftDown from 'openseadragon/build/openseadragon/images/rotateleft_pressed.png'

import rotateRightRest from 'openseadragon/build/openseadragon/images/rotateright_rest.png'
import rotateRightGroup from 'openseadragon/build/openseadragon/images/rotateright_grouphover.png'
import rotateRightHover from 'openseadragon/build/openseadragon/images/rotateright_hover.png'
import rotateRightDown from 'openseadragon/build/openseadragon/images/rotateright_pressed.png'

import previousRest from 'openseadragon/build/openseadragon/images/previous_rest.png'
import previousGroup from 'openseadragon/build/openseadragon/images/previous_grouphover.png'
import previousHover from 'openseadragon/build/openseadragon/images/previous_hover.png'
import previousDown from 'openseadragon/build/openseadragon/images/previous_pressed.png'

import nextRest from 'openseadragon/build/openseadragon/images/next_rest.png'
import nextGroup from 'openseadragon/build/openseadragon/images/next_grouphover.png'
import nextHover from 'openseadragon/build/openseadragon/images/next_hover.png'
import nextDown from 'openseadragon/build/openseadragon/images/next_pressed.png'

export default {
  zoomIn: { REST: zoomInRest, GROUP: zoomInGroup, HOVER: zoomInHover, DOWN: zoomInDown },
  zoomOut: { REST: zoomOutRest, GROUP: zoomOutGroup, HOVER: zoomOutHover, DOWN: zoomOutDown },
  home: { REST: homeRest, GROUP: homeGroup, HOVER: homeHover, DOWN: homeDown },
  fullpage: { REST: fullPageRest, GROUP: fullPageGroup, HOVER: fullPageHover, DOWN: fullPageDown },
  rotateleft: { REST: rotateLeftRest, GROUP: rotateLeftGroup, HOVER: rotateLeftHover, DOWN: rotateLeftDown },
  rotateright: { REST: rotateRightRest, GROUP: rotateRightGroup, HOVER: rotateRightHover, DOWN: rotateRightDown },
  previous: { REST: previousRest, GROUP: previousGroup, HOVER: previousHover, DOWN: previousDown },
  next: { REST: nextRest, GROUP: nextGroup, HOVER: nextHover, DOWN: nextDown }
}
