module Addicted

import Addicted.Helper

public abstract class HintRequest extends ScriptableSystemRequest {
  // game timestamp where to stop at
  protected let until: Float;
  protected let times: Int32 = 0;
  protected let threshold: Threshold;
  public func Sound() -> CName;
}

// hint for inhalers
public class CoughingRequest extends HintRequest {
  public func Sound() -> CName {
    if EnumInt(this.threshold) == EnumInt(Threshold.Severely) {
      return n"g_sc_v_sickness_cough_hard";
    }
    return n"g_sc_v_sickness_cough_light";
  }
}
// hint for pills
public class VomitingRequest extends HintRequest {
  public func Sound() -> CName {
    if EnumInt(this.threshold) == EnumInt(Threshold.Severely) {
      return n"g_sc_v_sickness_cough_blood";
    }
    return n"sq032_sc_04_v_pukes";
  }
}
// hint for injectors
public class AchingRequest extends HintRequest {
  public func Sound() -> CName {
    if EnumInt(this.threshold) == EnumInt(Threshold.Severely) {
      return n"ono_v_pain_long";
    }
    return n"ono_v_pain_short";
  }
}

public class Consumptions {
  private persistent let keys: array<TweakDBID>;
  private persistent let values: array<ref<Consumption>>;

  public func Insert(key: TweakDBID, value: ref<Consumption>) -> Void {
    if this.KeyExist(key) { return; }
    ArrayPush(this.values, value);
    ArrayPush(this.keys, key);
  }
  private func Index(key: TweakDBID) -> Int32 {
    let idx = 0;
    let found = false;
    for existing in this.keys {
      if existing == key {
        found = true;
        break;
      }
      idx += 1;
    }
    if found {
      return idx;
    }
    return -1;
  }
  public func Get(key: TweakDBID) -> ref<Consumption> {
    let idx = this.Index(key);
    if idx == -1 { return null; }
    return this.values[idx];
  }
  public func Set(key: TweakDBID, value: ref<Consumption>) -> Void {
    let idx = this.Index(key);
    if idx == -1 { return; }
    this.values[idx] = value;
  }
  public func KeyExist(key: TweakDBID) -> Bool {
    for existing in this.keys {
      if existing == key {
        return true;
      }
    }
    return false;
  }
  public func Remove(key: TweakDBID) -> Void {
    let idx = this.Index(key);
    if idx == -1 { return; }
    ArrayErase(this.keys, idx);
    ArrayErase(this.values, idx);
  }
  public func Clear() -> Void {
    ArrayClear(this.keys);
    ArrayClear(this.values);
  }
  public func Size() -> Int32 {
    let size = ArraySize(this.keys);
    return size;
  }
  public func Keys() -> array<TweakDBID> {
    return this.keys;
  }
}

public class Consumption {
  public persistent let current: Int32;
  public persistent let doses: array<Float>;

  public static func Create(id: TweakDBID, when: Float) -> ref<Consumption> {
    let consumption = new Consumption();
    consumption.current = Helper.Potency(id);
    consumption.doses = [when];
    return consumption;
  }
}

enum Category {
  Mild = 0,
  Hard = 1,
}

/// addiction thresholds
enum Threshold {
  Clean = 0,
  Barely = 10,
  Mildly = 20,
  Notably = 40,
  Severely = 60,
}

enum Consumable {
  Invalid = -1,
  Alcohol = 0,
  MaxDOC = 1, // FirstAidWhiff
  BounceBack = 2, // BonesMcCoy
  HealthBooster = 3,
  MemoryBooster = 4,
  OxyBooster = 5,
  StaminaBooster = 6,
  BlackLace = 7,
}

enum Kind {
  Inhaler = 0,
  Injector = 1,
  Pill = 2,
}

enum Addiction {
  Healers = 0,
}
