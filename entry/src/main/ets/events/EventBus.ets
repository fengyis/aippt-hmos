import { emitter } from '@kit.BasicServicesKit'
import { EventConstants } from './EventConstants'

export class EventBus {
  private static callbacks: Map<string, Set<(data: Object) => void>> = new Map()

  static on(event: string, callback: (data: Object) => void): void {
    if (!this.callbacks.has(event)) { this.callbacks.set(event, new Set()) }
    this.callbacks.get(event)!.add(callback)
  }

  static off(event: string, callback: (data: Object) => void): void {
    this.callbacks.get(event)?.delete(callback)
  }

  static emit(event: string, data?: Object): void {
    this.callbacks.get(event)?.forEach(cb => { try { cb(data ?? {}) } catch (_) {} })
  }

  static clear(): void { this.callbacks.clear() }
}
