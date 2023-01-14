module Addicted

import Addicted.Helper

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
  MaxDOC = 1, // BonesMcCoy
  BounceBack = 2, // FirstAidWhiff
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
