import { application } from "./application";
import CharacterCounterController from "./character_counter_controller";
import DisclosureController from "./disclosure_controller";

application.register("character-counter", CharacterCounterController);
application.register("disclosure", DisclosureController);
