module Addicted.System

import Addicted.Utils.*
import Addicted.*

public class AddictedSystem extends ScriptableSystem {
  
  private let player: wref<PlayerPuppet>;
  private let delaySystem: ref<DelaySystem>;
  private let timeSystem: ref<TimeSystem>;

  private let config: ref<AddictedConfig>;

  private let hintDelayID: DelayID;

  private persistent let consumptions: ref<inkHashMap>;
  private persistent let ids: array<TweakDBID>;

  private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    let player: ref<PlayerPuppet> = GetPlayer(this.GetGameInstance());
    if IsDefined(player) {
      E(s"initialize system on player attach");
      this.player = player;
      this.delaySystem = GameInstance.GetDelaySystem(this.player.GetGame());
      this.timeSystem = GameInstance.GetTimeSystem(this.player.GetGame());

      this.RefreshConfig();
    } else { F(s"no player found!"); }
  }

  private func OnAttach() -> Void {
    E(s"on attach system");
    if !IsDefined(this.consumptions) {
      E(s"no hashmap yet");
      this.consumptions = new inkHashMap();
    }
    ModSettings.RegisterListenerToModifications(this);
  }

  private func OnDetach() -> Void {
    E(s"on detach system");
    ModSettings.UnregisterListenerToModifications(this);
  }

  public func RefreshConfig() -> Void {
    E(s"refresh config");
    this.config = new AddictedConfig();
  }

  public func OnModSettingsChange() -> Void {
    this.RefreshConfig();
  }
  
  public final static func GetInstance(gameInstance: GameInstance) -> ref<AddictedSystem> {
    let container = GameInstance.GetScriptableSystemsContainer(gameInstance);
    return container.Get(n"Addicted.System.AddictedSystem") as AddictedSystem;
  }

  public func OnConsumed(id: TweakDBID) -> Void {
    let now = this.timeSystem.GetGameTimeStamp();
    let key = TDBID.ToNumber(id);
    if ArrayContains(this.ids, id) {
      let consumption: ref<Consumption> = this.consumptions.Get(key) as Consumption;
      let old = consumption.current;
      consumption.current = Min(consumption.current + Helper.Potency(id), 100);
      ArrayPush(consumption.doses, now);
      E(s"additional consumption \(TDBID.ToStringDEBUG(id)) \(ToString(old)) -> \(ToString(consumption.current))");
    } else {
      E(s"first time consumption for \(TDBID.ToStringDEBUG(id)) \(ToString(key))");
      this.consumptions.Insert(key, Consumption.Create(id, now));
      ArrayPush(this.ids, id);
    }
  }

  public func OnDissipated(id: TweakDBID) -> Void {
    let key = TDBID.ToNumber(id);
    let consumption: wref<Consumption> = this.consumptions.Get(key) as Consumption;
    E(s"on dissipation \(TDBID.ToStringDEBUG(id))");
    if IsDefined(consumption) {
      let consumable = Helper.Consumable(id);
      let current = this.AverageConsumption(consumable);
      let threshold = Helper.Threshold(current);
      E(s"current: \(current), threshold: \(threshold)");
      switch(threshold) {
        case Threshold.Severely:
        case Threshold.Notably:
          let request: ref<HintRequest>;
          if Helper.IsInhaler(id) {
            request = new CoughingRequest();
          }
          if Helper.IsPill(id) {
            request = new VomitingRequest();
          }
          if Helper.IsInjector(id) {
            request = new AchingRequest();
          }
          let now = this.timeSystem.GetGameTimeStamp();
          request.until = now + RandRangeF(3, 5);
          request.threshold = threshold;
          let delay = RandRangeF(1, 3);
          this.delaySystem.CancelDelay(this.hintDelayID);
          this.hintDelayID = this.delaySystem.DelayScriptableSystemRequest(this.GetClassName(), request, delay, true);
          break;
        default:
          break;
      }
    } else {
      FI(id, s"no consumption recorded while just dissipated");
    }
  }

  protected final func OnCoughingRequest(request: ref<CoughingRequest>) -> Void {
    E(s"TODO cough");
  }

  protected final func OnVomitingRequest(request: ref<VomitingRequest>) -> Void {
    E(s"TODO puke");
  }

  protected final func OnAchingRequest(request: ref<AchingRequest>) -> Void {
    E(s"TODO pain");
  }

  public func OnProcessHealerEffects(actionEffects: array<wref<ObjectActionEffect_Record>>) -> array<wref<ObjectActionEffect_Record>> {
    E(s"on process healer effects");
    let idx = 0;
    let action: TweakDBID;
    let threshold: Threshold;
    let consumable: Consumable;
    let average: Int32;
    let id: TweakDBID;
    let groupAverage = this.AverageAddiction(Addiction.Healers);
    let groupThreshold = Helper.Threshold(groupAverage);
    for effect in actionEffects {
      id = effect.GetID();
      consumable = Helper.Consumable(id);
      average = this.AverageConsumption(consumable);
      threshold = Helper.Threshold(average);
      if EnumInt(threshold) < EnumInt(groupThreshold) {
        threshold = groupThreshold;
      }
      action = Helper.ActionEffect(id, threshold);
      if !Equals(action, id) {
        EI(id, s"replace with \(TDBID.ToStringDEBUG(action))");
        let replaced = TweakDBInterface.GetObjectActionEffectRecord(action);
        actionEffects[idx] = replaced;
      }
      idx += 1;
    }
    return actionEffects;
  }

  public func AverageConsumption(consumable: Consumable) -> Int32 {
    let ids = Helper.Effects(consumable);
    let total = 0;
    let found = 0;
    let consumption: wref<Consumption>;
    for id in ids {
      consumption = this.consumptions.Get(TDBID.ToNumber(id)) as Consumption;
      if IsDefined(consumption) {
        total += consumption.current;
        found += 1;
      }
    }
    if found == 0 {
      return 0;
    }
    return total / found;
  }

  public func AverageAddiction(addiction: Addiction) -> Int32 {
    let consumables = Helper.Consumables(addiction);
    let size = ArraySize(consumables);
    let total = 0;
    for consumable in consumables {
      total += this.AverageConsumption(consumable);
    }
    return total / size;
  }

  public func Threshold(addiction: Addiction) -> Threshold {
    let average = this.AverageAddiction(addiction);
    return Helper.Threshold(average);
  }

  public func DebugSwitchThreshold(id: TweakDBID, threshold: Threshold) -> Void {
    let now = this.timeSystem.GetGameTimeStamp();
    let key = TDBID.ToNumber(id);
    if ArrayContains(this.ids, id) {
      let consumption: ref<Consumption> = this.consumptions.Get(key) as Consumption;
      let old = consumption.current;
      consumption.current = EnumInt(threshold) + 1;
      ArrayPush(consumption.doses, now);
      EI(id, s"update threshold: \(ToString(old)) -> \(ToString(consumption.current)) (\(ToString(key)))");
    } else {
      EI(id, s"add threshold (\(ToString(key)))");
      let consumption = new Consumption();
      consumption.current = EnumInt(threshold) + 1;
      consumption.doses = [now];
      this.consumptions.Insert(key, consumption);
      ArrayPush(this.ids, id);
    }
  }

  public func DebugThresholds() -> Void {
    E(s"debug thresholds:");
    let size = ArraySize(this.ids);
    if size == 0 {
      E(s"no consumption found!");
      return;
    }
    for id in this.ids {
      let key = TDBID.ToNumber(id);
      let consumption: ref<Consumption> = this.consumptions.Get(key) as Consumption;
      if IsDefined(consumption) {
        let size = ArraySize(consumption.doses);
        EI(id, s"current: \(ToString(consumption.current)) doses: \(ToString(size))");
      } else {
        FI(id, s"consumption found empty (\(ToString(key)))");
      }
    }
  }

  public func DebugClear() -> Void {
    E(s"clear all consumptions...");
    let size = ArraySize(this.ids);
    if size == 0 {
      E(s"no consumption found!");
      return;
    } else {
      let key: Uint64;
      for id in this.ids {
        key = TDBID.ToNumber(id);
        this.consumptions.Remove(key);
      }
      this.consumptions.Clear();
      this.consumptions = new inkHashMap();
      this.ids = [];
      E(s"consumption cleaned!");
    }
  }
}