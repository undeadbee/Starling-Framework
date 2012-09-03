// =================================================================================================
//
//	Starling Framework
//	Copyright 2011 Gamua OG. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

// =================================================================================================
//
//	Starling 框架
//	版权信息  2012 Gamua OG. 所有权利保留.
//
//	这个程序是免费软件. 你可以在协议范围内自由修改和再发布.
//
// =================================================================================================

package starling.core
{
    import flash.geom.Point;
    
    import starling.display.Stage;
    import starling.events.KeyboardEvent;
    import starling.events.Touch;
    import starling.events.TouchEvent;
    import starling.events.TouchPhase;

    use namespace starling_internal;
    
    /** @private
     *  The TouchProcessor is used internally to convert mouse and touch events of the conventional
     *  Flash stage to Starling's TouchEvents. */
	/** @private
	 *  TouchProcessor 仅包内部使用，转化普通的鼠标事件为Starling的触摸事件 . */
    internal class TouchProcessor
    {
        private static const MULTITAP_TIME:Number = 0.3;
        private static const MULTITAP_DISTANCE:Number = 25;
        
        private var mStage:Stage;
        private var mElapsedTime:Number;
        private var mOffsetTime:Number;
        private var mTouchMarker:TouchMarker;
        
        private var mCurrentTouches:Vector.<Touch>;
        private var mQueue:Vector.<Array>;
        private var mLastTaps:Vector.<Touch>;
        
        private var mShiftDown:Boolean = false;
        private var mCtrlDown:Boolean = false;
        
        /** Helper objects. */
		/** 帮助对象. */
        private static var sProcessedTouchIDs:Vector.<int> = new <int>[];
        private static var sHoveringTouchData:Vector.<Object> = new <Object>[];
        
        public function TouchProcessor(stage:Stage)
        {
            mStage = stage;
            mElapsedTime = mOffsetTime = 0.0;
            mCurrentTouches = new <Touch>[];
            mQueue = new <Array>[];
            mLastTaps = new <Touch>[];
            
            mStage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.addEventListener(KeyboardEvent.KEY_UP,   onKey);
        }

        public function dispose():void
        {
            mStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
            mStage.removeEventListener(KeyboardEvent.KEY_UP,   onKey);
            if (mTouchMarker) mTouchMarker.dispose();
        }
        
        public function advanceTime(passedTime:Number):void
        {
            var i:int;
            var touchID:int;
            var touch:Touch;
            
            mElapsedTime += passedTime;
            mOffsetTime = 0.0;
            
            // remove old taps
			// 移除旧的标签
            if (mLastTaps.length > 0)
            {
                for (i=mLastTaps.length-1; i>=0; --i)
                    if (mElapsedTime - mLastTaps[i].timestamp > MULTITAP_TIME)
                        mLastTaps.splice(i, 1);
            }
            
            while (mQueue.length > 0)
            {
                sProcessedTouchIDs.length = sHoveringTouchData.length = 0;
                
                // update existing touches
				// 更新存在的触摸
                for each (touch in mCurrentTouches)
                {
                    // set touches that were new or moving to phase 'stationary'
					// 设置新的或者是不动的触摸
                    if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
                        touch.setPhase(TouchPhase.STATIONARY);
                    
                    // check if target is still connected to stage, otherwise find new target
					// 检测目标是否仍然和舞台关联，没有关联则寻找新的目标
                    if (touch.target && touch.target.stage == null)
                        touch.setTarget(mStage.hitTest(
                            new Point(touch.globalX, touch.globalY), true));
                }
                
                // process new touches, but each ID only once
				// 处理新的触摸，但是每个ID只处理一次
                while (mQueue.length > 0 && 
                    sProcessedTouchIDs.indexOf(mQueue[mQueue.length-1][0]) == -1)
                {
                    var touchArgs:Array = mQueue.pop();
                    touchID = touchArgs[0] as int;
                    touch = getCurrentTouch(touchID);
                    
                    // hovering touches need special handling (see below)
					// 把需要特殊处理的触摸挂起 (参看下面)
                    if (touch && touch.phase == TouchPhase.HOVER && touch.target)
                        sHoveringTouchData.push({ touch: touch, target: touch.target });
                    
                    processTouch.apply(this, touchArgs);
                    sProcessedTouchIDs.push(touchID);
                }
                
                // if the target of a hovering touch changed, we dispatch an event to the previous
                // target to notify it that it's no longer being hovered over.
				// 如果挂起的触摸改变，我们将会给它派发事件通知它不再被挂起。
                for each (var touchData:Object in sHoveringTouchData)
                    if (touchData.touch.target != touchData.target)
                        touchData.target.dispatchEvent(new TouchEvent(
                            TouchEvent.TOUCH, mCurrentTouches, mShiftDown, mCtrlDown));
                
                // dispatch events
				// 派发事件
                for each (touchID in sProcessedTouchIDs)
                {
                    touch = getCurrentTouch(touchID);
                    
                    if (touch.target)
                        touch.target.dispatchEvent(new TouchEvent(TouchEvent.TOUCH, mCurrentTouches,
                                                                  mShiftDown, mCtrlDown));
                }
                
                // remove ended touches
				// 删除结束了的触摸
                for (i=mCurrentTouches.length-1; i>=0; --i)
                    if (mCurrentTouches[i].phase == TouchPhase.ENDED)
                        mCurrentTouches.splice(i, 1);
                
                // timestamps must differ for remaining touches
				// 时间戳徐珌和保留的触摸不同
                mOffsetTime += 0.00001;
            }
        }
        
        public function enqueue(touchID:int, phase:String, globalX:Number, globalY:Number):void
        {
            mQueue.unshift(arguments);
            
            // multitouch simulation (only with mouse)
			// 多点触摸模拟 (只对鼠标有效)
            if (mCtrlDown && simulateMultitouch && touchID == 0) 
            {
                mTouchMarker.moveMarker(globalX, globalY, mShiftDown);
                mQueue.unshift([1, phase, mTouchMarker.mockX, mTouchMarker.mockY]);
            }
        }
        
        private function processTouch(touchID:int, phase:String, globalX:Number, globalY:Number):void
        {
            var position:Point = new Point(globalX, globalY);
            var touch:Touch = getCurrentTouch(touchID);
            
            if (touch == null)
            {
                touch = new Touch(touchID, globalX, globalY, phase, null);
                addCurrentTouch(touch);
            }
            
            touch.setPosition(globalX, globalY);
            touch.setPhase(phase);
            touch.setTimestamp(mElapsedTime + mOffsetTime);
            
            if (phase == TouchPhase.HOVER || phase == TouchPhase.BEGAN)
                touch.setTarget(mStage.hitTest(position, true));
            
            if (phase == TouchPhase.BEGAN)
                processTap(touch);
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (event.keyCode == 17 || event.keyCode == 15) // ctrl or cmd key
            {
                var wasCtrlDown:Boolean = mCtrlDown;
                mCtrlDown = event.type == KeyboardEvent.KEY_DOWN;
                
                if (simulateMultitouch && wasCtrlDown != mCtrlDown)
                {
                    mTouchMarker.visible = mCtrlDown;
                    mTouchMarker.moveCenter(mStage.stageWidth/2, mStage.stageHeight/2);
                    
                    var mouseTouch:Touch = getCurrentTouch(0);
                    var mockedTouch:Touch = getCurrentTouch(1);
                    
                    if (mouseTouch)
                        mTouchMarker.moveMarker(mouseTouch.globalX, mouseTouch.globalY);
                    
                    // end active touch ...
					// 结束活动中的触摸 ...
                    if (wasCtrlDown && mockedTouch && mockedTouch.phase != TouchPhase.ENDED)
                        mQueue.unshift([1, TouchPhase.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
                    // ... or start new one
					// ... 或者启动一个新触摸
                    else if (mCtrlDown && mouseTouch)
                    {
                        if (mouseTouch.phase == TouchPhase.BEGAN || mouseTouch.phase == TouchPhase.MOVED)
                            mQueue.unshift([1, TouchPhase.BEGAN, mTouchMarker.mockX, mTouchMarker.mockY]);
                        else
                            mQueue.unshift([1, TouchPhase.HOVER, mTouchMarker.mockX, mTouchMarker.mockY]);
                    }
                }
            }
            else if (event.keyCode == 16) // shift key // shift 按键 
            {
                mShiftDown = event.type == KeyboardEvent.KEY_DOWN;
            }
        }
        
        private function processTap(touch:Touch):void
        {
            var nearbyTap:Touch = null;
            var minSqDist:Number = MULTITAP_DISTANCE * MULTITAP_DISTANCE;
            
            for each (var tap:Touch in mLastTaps)
            {
                var sqDist:Number = Math.pow(tap.globalX - touch.globalX, 2) +
                                    Math.pow(tap.globalY - touch.globalY, 2);
                if (sqDist <= minSqDist)
                {
                    nearbyTap = tap;
                    break;
                }
            }
            
            if (nearbyTap)
            {
                touch.setTapCount(nearbyTap.tapCount + 1);
                mLastTaps.splice(mLastTaps.indexOf(nearbyTap), 1);
            }
            else
            {
                touch.setTapCount(1);
            }
            
            mLastTaps.push(touch.clone());
        }
        
        private function addCurrentTouch(touch:Touch):void
        {
            for (var i:int=mCurrentTouches.length-1; i>=0; --i)
                if (mCurrentTouches[i].id == touch.id)
                    mCurrentTouches.splice(i, 1);
            
            mCurrentTouches.push(touch);
        }
        
        private function getCurrentTouch(touchID:int):Touch
        {
            for each (var touch:Touch in mCurrentTouches)
                if (touch.id == touchID) return touch;
            return null;
        }
        
        public function get simulateMultitouch():Boolean { return mTouchMarker != null; }
        public function set simulateMultitouch(value:Boolean):void
        { 
            if (simulateMultitouch == value) return; // no change // 没有改变
            if (value)
            {
                mTouchMarker = new TouchMarker();
                mTouchMarker.visible = false;
                mStage.addChild(mTouchMarker);
            }
            else
            {                
                mTouchMarker.removeFromParent(true);
                mTouchMarker = null;
            }
        }
    }
}
