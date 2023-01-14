module Addicted

import Addicted.System.AddictedSystem
import Addicted.Helper
import Addicted.Utils.E

@wrapMethod(PlayerPuppet)
protected cb func OnStatusEffectApplied(evt: ref<ApplyStatusEffectEvent>) -> Bool {
    wrappedMethod(evt);
    let system = AddictedSystem.GetInstance(this.GetGame());
    let id = evt.staticData.GetID();
    E(s"status effect applied \(TDBID.ToStringDEBUG(id))");
    // increase score on consumption
    if evt.isNewApplication && evt.IsAddictive() {
        E(s"consumed addictive substance \(TDBID.ToStringDEBUG(id))");
        system.OnConsumed(id);
    }
    // decrease score on rest
    if id == t"HousingStatusEffect.Rested" {
        E(s"rested \(TDBID.ToStringDEBUG(id))");
    }
}

@addMethod(StatusEffectEvent)
public func IsAddictive() -> Bool {
  let id = this.staticData.GetID();
  return Helper.IsAddictive(id);
}