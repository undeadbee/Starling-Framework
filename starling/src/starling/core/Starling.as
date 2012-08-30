// =================================================================================================
//
//	Starling Framework
//	Copyright 2012 Gamua OG. All Rights Reserved.
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
    import flash.display.Sprite;
    import flash.display.Stage3D;
    import flash.display3D.Context3D;
    import flash.display3D.Program3D;
    import flash.errors.IllegalOperationError;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.TouchEvent;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.ui.Mouse;
    import flash.ui.Multitouch;
    import flash.ui.MultitouchInputMode;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.getTimer;
    import flash.utils.setTimeout;
    
    import starling.animation.Juggler;
    import starling.display.DisplayObject;
    import starling.display.Stage;
    import starling.events.EventDispatcher;
    import starling.events.ResizeEvent;
    import starling.events.TouchPhase;
    import starling.utils.HAlign;
    import starling.utils.VAlign;
    
    /** 新的渲染环境创建后派发事件. */
    [Event(name="context3DCreate", type="starling.events.Event")]
    
    /** 根类创建后派发事件. */
    [Event(name="rootCreated", type="starling.events.Event")]
    
    /** Starling类展现了Starling框架的核心.
     *
     *  <p>Starling框架让使用Stage3D技术(在flash player 11中引入)创建二维程序和游戏成为可能。 它实现了和Flash
	 * 	一样的显示列表系统，同时使用先进的GPUs加速渲染. </p>
     *  
     *  <p>Starling类展示了Flash显示列表和Starling显示列表之间的结构关系。创建一个Starling应用程序，你必须首先
	 * 	创建一个Starling类的实例对象。</p>
     *  
     *  <pre>var starling:Starling = new Starling(Game, stage);</pre>
     *  
     *  <p>第一个参数必须是Starling的显示类。例如<code>starling.display.Sprite</code>的子类，在上面的例子
	 * 	中，类“Game”是程序的根。当Starling初始化后“Game”的对象也随之创建。
	 * 	第二个参数是FLash本身的stage对象，在默认情况下，Starling会在stage下层显示内容。
     *  
     *  <p>建议保存Starling对象作为成员变量，这样可以保证垃圾回收系统不会销毁它。在创建Starling对象后，你必须这样启动它：</p>
     * 
     *  <pre>starling.start();</pre>
     * 
     *  <p>现在它会按照为程序设置好帧频率（和设置Flash stage的方法一样）来渲染“Game”类的内容了.</p> 
     *  
     *  <strong>访问Starling对象</strong>
     * 
     *  <p>在你的程序里，你可以在任意时间通过静态方法<code>Starling.current</code>访问当前的Starling对象。它会返回
	 * 	当前活跃的Starling实例（实际上大多数程序只会有一个Starling对象）。</p> 
     * 
     *  <strong>观察口，视口</strong>
     * 
     *  <p>即是Starling内容渲染显示的范围，默认情况下是舞台大小。但是，你可以使用“viewport”属性去改变它。当你只想在屏幕的一部分中
	 * 	渲染，或者播放器大小改变时，这个属性非常有用。随后你可以监听由Starling舞台发出的RESIZE事件。</p>
     * 
     *  <strong>原生Flash叠加层</strong>
     *  
     *  <p>有时你会想在Starling上面显示一些原生Flash内容，这就是<code>nativeOverlay</code>属性的作用。它返回的是在Starling之上
	 * 	的原生FLash Sprite。你可以在叠加层内添加原生Flash对象。</p>
     *  
     *  <p>但是需要注意，在3D加速内容之上的原生Flash内容在某些（移动）平台上会有性能上的问题。因为这个原因，请注意删除这一层中所有
	 * 	不需要和不再使用的对象。当这一层被置空后Starling会从显示列表中删除原生Flash叠加层。</p>
     *  
     *  <strong>多点触摸</strong>
     *  
     *  <p>对于提供支持多点触摸功能的设备，Starling也支持这项功能。在开发过程中，我们大多数基本上都是使用鼠标的键盘，Starling可以
	 * 	在“Shift”和“Ctrl”的帮助下（Mac苹果机是“Cmd”）模拟实现多点触摸事件。启动<code>simulateMultitouch</code>属性就可以激活
	 * 	这个功能。
     *  
     *  <strong>处理丢失的渲染内容</strong>
     *  
     *  <p>在某些系统和某些条件下（例如，从系统睡眠中返回），Starling的stage3D渲染内容会丢失。如果类属性“handleLostContext”
	 * 	设置为 “true” Starling会自动修复丢失内容。但是需要注意，这是以提高内存消耗为代价的。Starling会在内存中创建纹理缓存，这样
	 * 	在内容丢失时才可以修复它。</p> 
     *  
     *  <p>如果你想和丢失的内容交互，Starling在这个内容修复时发送"Event.CONTEXT3D_CREATE"事件，你可以在相对应的事件监听器中重新
	 * 	创建这些不可用资源.</p>
     * 
     *  <strong>共享三维加速内容</strong>
     * 
     *  <p>正常情况下，Starling是独立处理stage3d加速内容。如果你想让Starling和其它的stage3d引擎同时使用，可能会达不到你需要的效果。
	 * 	在这种情况下，你可以使用<code>shareContext</code>属性:</p> 
     *  
     *  <ol>
     *    <li>Manually create and configure a context3D object that both frameworks can work with
     *        (through <code>stage3D.requestContext3D</code> and
     *        <code>context.configureBackBuffer</code>).</li>
     *    <li>Initialize Starling with the stage3D instance that contains that configured context.
     *        This will automatically enable <code>shareContext</code>.</li>
     *    <li>Call <code>start()</code> on your Starling instance (as usual). This will make  
     *        Starling queue input events (keyboard/mouse/touch).</li>
     *    <li>Create a game loop (e.g. using the native <code>ENTER_FRAME</code> event) and let it  
     *        call Starling's <code>nextFrame</code> as well as the equivalent method of the other 
     *        Stage3D engine. Surround those calls with <code>context.clear()</code> and 
     *        <code>context.present()</code>.</li>
     *  </ol>
	 * 
     */ 
    public class Starling extends EventDispatcher
    {
        /** The version of the Starling framework. */
        public static const VERSION:String = "1.2";
        
        // members
        
        private var mStage3D:Stage3D;
        private var mStage:Stage; // starling.display.stage!
        private var mRootClass:Class;
        private var mJuggler:Juggler;
        private var mStarted:Boolean;        
        private var mSupport:RenderSupport;
        private var mTouchProcessor:TouchProcessor;
        private var mAntiAliasing:int;
        private var mSimulateMultitouch:Boolean;
        private var mEnableErrorChecking:Boolean;
        private var mLastFrameTimestamp:Number;
        private var mViewPort:Rectangle;
        private var mLeftMouseDown:Boolean;
        private var mStatsDisplay:StatsDisplay;
        private var mShareContext:Boolean;
        
        private var mNativeStage:flash.display.Stage;
        private var mNativeOverlay:flash.display.Sprite;
        
        private var mContext:Context3D;
        private var mPrograms:Dictionary;
        
        private static var sCurrent:Starling;
        private static var sHandleLostContext:Boolean;
        
        // construction
        
        /** Creates a new Starling instance. 
         *  @param rootClass  A subclass of a Starling display object. It will be created as soon as
         *                    initialization is finished and will become the first child of the
         *                    Starling stage.
         *  @param stage      The Flash (2D) stage.
         *  @param viewPort   A rectangle describing the area into which the content will be 
         *                    rendered. @default stage size
         *  @param stage3D    The Stage3D object into which the content will be rendered. If it 
         *                    already contains a context, <code>sharedContext</code> will be set
         *                    to <code>true</code>. @default the first available Stage3D.
         *  @param renderMode Use this parameter to force "software" rendering. 
         *  @param profile    The Context3DProfile that should be requested.
         */
        public function Starling(rootClass:Class, stage:flash.display.Stage, 
                                 viewPort:Rectangle=null, stage3D:Stage3D=null,
                                 renderMode:String="auto", profile:String="baselineConstrained") 
        {
            if (stage == null) throw new ArgumentError("Stage must not be null");
            if (rootClass == null) throw new ArgumentError("Root class must not be null");
            if (viewPort == null) viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
            if (stage3D == null) stage3D = stage.stage3Ds[0];
            
            makeCurrent();
            
            mRootClass = rootClass;
            mViewPort = viewPort;
            mStage3D = stage3D;
            mStage = new Stage(viewPort.width, viewPort.height, stage.color);
            mNativeOverlay = new Sprite();
            mNativeStage = stage;
            mNativeStage.addChild(mNativeOverlay);
            mTouchProcessor = new TouchProcessor(mStage);
            mJuggler = new Juggler();
            mAntiAliasing = 0;
            mSimulateMultitouch = false;
            mEnableErrorChecking = false;
            mLastFrameTimestamp = getTimer() / 1000.0;
            mPrograms = new Dictionary();
            mSupport  = new RenderSupport();
            
            // register touch/mouse event handlers            
            for each (var touchEventType:String in touchEventTypes)
                stage.addEventListener(touchEventType, onTouch, false, 0, true);
            
            // register other event handlers
            stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
            stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
            
            if (mStage3D.context3D && mStage3D.context3D.driverInfo != "Disposed")
            {
                mShareContext = true;
                setTimeout(initialize, 1); // we don't call it right away, because Starling should
                                           // behave the same way with or without a shared context
            }
            else
            {
                mShareContext = false;
                mStage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 1, true);
                mStage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 1, true);
                
                try
                {
                    // "Context3DProfile" is only available starting with Flash Player 11.4/AIR 3.4.
                    // to stay compatible with older versions, we check if the parameter is available.
                    
                    var requestContext3D:Function = mStage3D.requestContext3D;
                    if (requestContext3D.length == 1) requestContext3D(renderMode);
                    else requestContext3D(renderMode, profile);
                }
                catch (e:Error)
                {
                    showFatalError("Context3D error: " + e.message);
                }
            }
        }
        
        /** Disposes Shader programs and render context. */
        public function dispose():void
        {
            stop();
            
            mNativeStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, false);
            mNativeStage.removeEventListener(KeyboardEvent.KEY_UP, onKey, false);
            mNativeStage.removeEventListener(Event.RESIZE, onResize, false);
            
            mStage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false);
            mStage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError, false);
            
            for each (var touchEventType:String in touchEventTypes)
                mNativeStage.removeEventListener(touchEventType, onTouch, false);
            
            for each (var program:Program3D in mPrograms)
                program.dispose();
            
            if (mContext && !mShareContext) mContext.dispose();
            if (mTouchProcessor) mTouchProcessor.dispose();
            if (mSupport) mSupport.dispose();
            if (mStage) mStage.dispose();
            if (sCurrent == this) sCurrent = null;
        }
        
        // functions
        
        private function initialize():void
        {
            makeCurrent();
            
            initializeGraphicsAPI();
            initializeRoot();
            
            mTouchProcessor.simulateMultitouch = mSimulateMultitouch;
            mLastFrameTimestamp = getTimer() / 1000.0;
        }
        
        private function initializeGraphicsAPI():void
        {
            mContext = mStage3D.context3D;
            mContext.enableErrorChecking = mEnableErrorChecking;
            mPrograms = new Dictionary();
            
            updateViewPort();
            
            trace("[Starling] Initialization complete.");
            trace("[Starling] Display Driver:", mContext.driverInfo);
            
            dispatchEventWith(starling.events.Event.CONTEXT3D_CREATE, false, mContext);
        }
        
        private function initializeRoot():void
        {
            if (mStage.numChildren > 0) return;
            
            var rootObject:DisplayObject = new mRootClass();
            if (rootObject == null) throw new Error("Invalid root class: " + mRootClass);
            mStage.addChildAt(rootObject, 0);
            
            dispatchEventWith(starling.events.Event.ROOT_CREATED, false, root);
        }
        
        /** Calls <code>advanceTime()</code> (with the time that has passed since the last frame)
         *  and <code>render()</code>. */ 
        public function nextFrame():void
        {
            var now:Number = getTimer() / 1000.0;
            var passedTime:Number = now - mLastFrameTimestamp;
            mLastFrameTimestamp = now;
            
            advanceTime(passedTime);
            render();
        }
        
        /** Dispatches ENTER_FRAME events on the display list, advances the Juggler 
         *  and processes touches. */
        public function advanceTime(passedTime:Number):void
        {
            makeCurrent();
            
            mTouchProcessor.advanceTime(passedTime);
            mStage.advanceTime(passedTime);
            mJuggler.advanceTime(passedTime);
        }
        
        /** Renders the complete display list. Before rendering, the context is cleared; afterwards,
         *  it is presented. This can be avoided by enabling <code>shareContext</code>.*/ 
        public function render():void
        {
            makeCurrent();
            updateNativeOverlay();
            mSupport.nextFrame();
            
            if (mContext == null || mContext.driverInfo == "Disposed")
                return;
            
            if (!mShareContext)
                RenderSupport.clear(mStage.color, 1.0);
            
            mSupport.setOrthographicProjection(mStage.stageWidth, mStage.stageHeight);
            mStage.render(mSupport, 1.0);
            mSupport.finishQuadBatch();
            
            if (mStatsDisplay)
                mStatsDisplay.drawCount = mSupport.drawCount;
            
            if (!mShareContext)
                mContext.present();
        }
        
        private function updateViewPort():void
        {
            if (mShareContext) return;
            
            if (mContext && mContext.driverInfo != "Disposed")
                mContext.configureBackBuffer(mViewPort.width, mViewPort.height, mAntiAliasing, false);
            
            mStage3D.x = mViewPort.x;
            mStage3D.y = mViewPort.y;
        }

        private function updateNativeOverlay():void
        {
            mNativeOverlay.x = mViewPort.x;
            mNativeOverlay.y = mViewPort.y;
            mNativeOverlay.scaleX = mViewPort.width / mStage.stageWidth;
            mNativeOverlay.scaleY = mViewPort.height / mStage.stageHeight;
        }
        
        private function showFatalError(message:String):void
        {
            var textField:TextField = new TextField();
            var textFormat:TextFormat = new TextFormat("Verdana", 12, 0xFFFFFF);
            textFormat.align = TextFormatAlign.CENTER;
            textField.defaultTextFormat = textFormat;
            textField.wordWrap = true;
            textField.width = mStage.stageWidth * 0.75;
            textField.autoSize = TextFieldAutoSize.CENTER;
            textField.text = message;
            textField.x = (mStage.stageWidth - textField.width) / 2;
            textField.y = (mStage.stageHeight - textField.height) / 2;
            textField.background = true;
            textField.backgroundColor = 0x440000;
            nativeOverlay.addChild(textField);
        }
        
        /** Make this Starling instance the <code>current</code> one. */
        public function makeCurrent():void
        {
            sCurrent = this;
        }
        
        /** As soon as Starling is started, it will queue input events (keyboard/mouse/touch);   
         *  furthermore, the method <code>nextFrame</code> will be called once per Flash Player
         *  frame. (Except when <code>shareContext</code> is enabled: in that case, you have to
         *  call that method manually.) */
        public function start():void 
        { 
            mStarted = true; 
            mLastFrameTimestamp = getTimer() / 1000.0;
        }
        
        /** Stops rendering. */
        public function stop():void 
        { 
            mStarted = false; 
        }
        
        // event handlers
        
        private function onStage3DError(event:ErrorEvent):void
        {
            if (event.errorID == 3702)
                showFatalError("This application is not correctly embedded (wrong wmode value)");
            else
                showFatalError("Stage3D error: " + event.text);
        }
        
        private function onContextCreated(event:Event):void
        {
            if (!Starling.handleLostContext && mContext)
            {
                showFatalError("Fatal error: The application lost the device context!");
                stop();
            }
            else
            {
                initialize();
            }
        }
        
        private function onEnterFrame(event:Event):void
        {
            if (mStarted && !mShareContext) 
                nextFrame();
        }
        
        private function onKey(event:KeyboardEvent):void
        {
            if (!mStarted) return;
            
            makeCurrent();
            mStage.dispatchEvent(new starling.events.KeyboardEvent(
                event.type, event.charCode, event.keyCode, event.keyLocation, 
                event.ctrlKey, event.altKey, event.shiftKey));
        }
        
        private function onResize(event:flash.events.Event):void
        {
            var stage:flash.display.Stage = event.target as flash.display.Stage; 
            mStage.dispatchEvent(new ResizeEvent(Event.RESIZE, stage.stageWidth, stage.stageHeight));
        }

        private function onTouch(event:Event):void
        {
            if (!mStarted) return;
            
            var globalX:Number;
            var globalY:Number;
            var touchID:int;
            var phase:String;
            
            // figure out general touch properties
            if (event is MouseEvent)
            {
                var mouseEvent:MouseEvent = event as MouseEvent;
                globalX = mouseEvent.stageX;
                globalY = mouseEvent.stageY;
                touchID = 0;
                
                // MouseEvent.buttonDown returns true for both left and right button (AIR supports
                // the right mouse button). We only want to react on the left button for now,
                // so we have to save the state for the left button manually.
                if (event.type == MouseEvent.MOUSE_DOWN)    mLeftMouseDown = true;
                else if (event.type == MouseEvent.MOUSE_UP) mLeftMouseDown = false;
            }
            else
            {
                var touchEvent:TouchEvent = event as TouchEvent;
                globalX = touchEvent.stageX;
                globalY = touchEvent.stageY;
                touchID = touchEvent.touchPointID;
            }
            
            // figure out touch phase
            switch (event.type)
            {
                case TouchEvent.TOUCH_BEGIN: phase = TouchPhase.BEGAN; break;
                case TouchEvent.TOUCH_MOVE:  phase = TouchPhase.MOVED; break;
                case TouchEvent.TOUCH_END:   phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_DOWN:  phase = TouchPhase.BEGAN; break;
                case MouseEvent.MOUSE_UP:    phase = TouchPhase.ENDED; break;
                case MouseEvent.MOUSE_MOVE: 
                    phase = (mLeftMouseDown ? TouchPhase.MOVED : TouchPhase.HOVER); break;
            }
            
            // move position into viewport bounds
            globalX = mStage.stageWidth  * (globalX - mViewPort.x) / mViewPort.width;
            globalY = mStage.stageHeight * (globalY - mViewPort.y) / mViewPort.height;
            
            // enqueue touch in touch processor
            mTouchProcessor.enqueue(touchID, phase, globalX, globalY);
        }
        
        private function get touchEventTypes():Array
        {
            return Mouse.supportsCursor || !multitouchEnabled ?
                [ MouseEvent.MOUSE_DOWN,  MouseEvent.MOUSE_MOVE, MouseEvent.MOUSE_UP ] :
                [ TouchEvent.TOUCH_BEGIN, TouchEvent.TOUCH_MOVE, TouchEvent.TOUCH_END ];  
        }
        
        // program management
        
        /** Registers a vertex- and fragment-program under a certain name. */
        public function registerProgram(name:String, vertexProgram:ByteArray, fragmentProgram:ByteArray):void
        {
            if (name in mPrograms)
                throw new Error("Another program with this name is already registered");
            
            var program:Program3D = mContext.createProgram();
            program.upload(vertexProgram, fragmentProgram);            
            mPrograms[name] = program;
        }
        
        /** Deletes the vertex- and fragment-programs of a certain name. */
        public function deleteProgram(name:String):void
        {
            var program:Program3D = getProgram(name);            
            if (program)
            {                
                program.dispose();
                delete mPrograms[name];
            }
        }
        
        /** Returns the vertex- and fragment-programs registered under a certain name. */
        public function getProgram(name:String):Program3D
        {
            return mPrograms[name] as Program3D;
        }
        
        /** Indicates if a set of vertex- and fragment-programs is registered under a certain name. */
        public function hasProgram(name:String):Boolean
        {
            return name in mPrograms;
        }
        
        // properties
        
        /** Indicates if this Starling instance is started. */
        public function get isStarted():Boolean { return mStarted; }
        
        /** The default juggler of this instance. Will be advanced once per frame. */
        public function get juggler():Juggler { return mJuggler; }
        
        /** The render context of this instance. */
        public function get context():Context3D { return mContext; }
        
        /** Indicates if multitouch simulation with "Shift" and "Ctrl"/"Cmd"-keys is enabled. 
         *  @default false */
        public function get simulateMultitouch():Boolean { return mSimulateMultitouch; }
        public function set simulateMultitouch(value:Boolean):void
        {
            mSimulateMultitouch = value;
            if (mContext) mTouchProcessor.simulateMultitouch = value;
        }
        
        /** Indicates if Stage3D render methods will report errors. Activate only when needed,
         *  as this has a negative impact on performance. @default false */
        public function get enableErrorChecking():Boolean { return mEnableErrorChecking; }
        public function set enableErrorChecking(value:Boolean):void 
        { 
            mEnableErrorChecking = value;
            if (mContext) mContext.enableErrorChecking = value; 
        }
        
        /** The antialiasing level. 0 - no antialasing, 16 - maximum antialiasing. @default 0 */
        public function get antiAliasing():int { return mAntiAliasing; }
        public function set antiAliasing(value:int):void
        {
            mAntiAliasing = value;
            updateViewPort();
        }
        
        /** The viewport into which Starling contents will be rendered. */
        public function get viewPort():Rectangle { return mViewPort.clone(); }
        public function set viewPort(value:Rectangle):void
        {
            mViewPort = value.clone();
            updateViewPort();
        }
        
        /** The ratio between viewPort width and stage width. Useful for choosing a different
         *  set of textures depending on the display resolution. */
        public function get contentScaleFactor():Number
        {
            return mViewPort.width / mStage.stageWidth;
        }
        
        /** A Flash Sprite placed directly on top of the Starling content. Use it to display native
         *  Flash components. */ 
        public function get nativeOverlay():Sprite { return mNativeOverlay; }
        
        /** Indicates if a small statistics box (with FPS, memory usage and draw count) is displayed. */
        public function get showStats():Boolean { return mStatsDisplay != null; }
        public function set showStats(value:Boolean):void
        {
            if (mStatsDisplay && !value)
            {
                mStatsDisplay.removeFromParent(true);
                mStatsDisplay = null;
            }
            else if (!mStatsDisplay && value)
            {
                showStatsAt();
            }
        }
        
        /** Displays the statistics box at a certain position. */
        public function showStatsAt(hAlign:String="left", vAlign:String="top", scale:Number=1):void
        {
            if (mContext == null)
            {
                // Starling is not yet ready - we postpone this until it's initialized.
                addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
            else
            {
                if (mStatsDisplay == null)
                {
                    mStatsDisplay = new StatsDisplay();
                    mStatsDisplay.touchable = false;
                    mStatsDisplay.scaleX = mStatsDisplay.scaleY = scale;
                    mStage.addChild(mStatsDisplay);
                }
                
                var stageWidth:int  = mStage.stageWidth;
                var stageHeight:int = mStage.stageHeight;
                
                if (hAlign == HAlign.LEFT) mStatsDisplay.x = 0;
                else if (hAlign == HAlign.RIGHT) mStatsDisplay.x = stageWidth - mStatsDisplay.width; 
                else mStatsDisplay.x = int((stageWidth - mStatsDisplay.width) / 2);
                
                if (vAlign == VAlign.TOP) mStatsDisplay.y = 0;
                else if (vAlign == VAlign.BOTTOM) mStatsDisplay.y = stageHeight - mStatsDisplay.height;
                else mStatsDisplay.y = int((stageHeight - mStatsDisplay.height) / 2);
            }
            
            function onRootCreated():void
            {
                showStatsAt(hAlign, vAlign, scale);
                removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
            }
        }
        
        /** The Starling stage object, which is the root of the display tree that is rendered. */
        public function get stage():Stage
        {
            return mStage;
        }

        /** The Flash Stage3D object Starling renders into. */
        public function get stage3D():Stage3D
        {
            return mStage3D;
        }
        
        /** The Flash (2D) stage object Starling renders beneath. */
        public function get nativeStage():flash.display.Stage
        {
            return mNativeStage;
        }
        
        /** The instance of the root class provided in the constructor. Available as soon as 
         *  the event 'ROOT_CREATED' has been dispatched. */
        public function get root():DisplayObject
        {
            return mStage.getChildAt(0);
        }
        
        /** Indicates if the Context3D render calls are managed externally to Starling, 
         *  to allow other frameworks to share the Stage3D instance. @default false */
        public function get shareContext() : Boolean { return mShareContext; }
        public function set shareContext(value : Boolean) : void { mShareContext = value; }
        
        // static properties
        
        /** The currently active Starling instance. */
        public static function get current():Starling { return sCurrent; }
        
        /** The render context of the currently active Starling instance. */
        public static function get context():Context3D { return sCurrent ? sCurrent.context : null; }
        
        /** The default juggler of the currently active Starling instance. */
        public static function get juggler():Juggler { return sCurrent ? sCurrent.juggler : null; }
        
        /** The contentScaleFactor of the currently active Starling instance. */
        public static function get contentScaleFactor():Number 
        {
            return sCurrent ? sCurrent.contentScaleFactor : 1.0;
        }
        
        /** Indicates if multitouch input should be supported. */
        public static function get multitouchEnabled():Boolean 
        { 
            return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
        }
        
        public static function set multitouchEnabled(value:Boolean):void
        {
            if (sCurrent) throw new IllegalOperationError(
                "'multitouchEnabled' must be set before Starling instance is created");
            else 
                Multitouch.inputMode = value ? MultitouchInputMode.TOUCH_POINT :
                                               MultitouchInputMode.NONE;
        }
        
        /** Indicates if Starling should automatically recover from a lost device context.
         *  On some systems, an upcoming screensaver or entering sleep mode may 
         *  invalidate the render context. This setting indicates if Starling should recover from 
         *  such incidents. Beware that this has a huge impact on memory consumption!
         *  It is recommended to enable this setting on Android and Windows, but to deactivate it
         *  on iOS and Mac OS X. @default false */
        public static function get handleLostContext():Boolean { return sHandleLostContext; }
        public static function set handleLostContext(value:Boolean):void 
        {
            if (sCurrent) throw new IllegalOperationError(
                "'handleLostContext' must be set before Starling instance is created");
            else
                sHandleLostContext = value;
        }
    }
}