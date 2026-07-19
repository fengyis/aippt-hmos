/**
 * ShortCutPage — 透明中转页（modal_overlay）
 *
 * 对应 Android ShortCutActivity：透明主题，无 UI 布局，启动后立即路由到目标页面。
 * HarmonyOS 端在 aboutToAppear 中解析快捷方式参数并跳转，用户无感知。
 */
@Entry
@ComponentV2
struct ShortCutPage {
  @Consumer('navPathStack') navPathStack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.navPathStack.pushPathByName('SplashPage', new Object());
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent);
  }
}
