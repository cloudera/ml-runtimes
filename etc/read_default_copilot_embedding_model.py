import json
import os
import os.path

# Default value to pass, if we cannot find any default copilot embedding models.
DEFAULT_COPILOT_EMBEDDING_MODEL = "None"

copilot_embedding_config_dir = os.getenv("COPILOT_EMBEDDING_CONFIG_DIR") or ""
if copilot_embedding_config_dir == "" or not os.path.isfile(copilot_embedding_config_dir):
    print(DEFAULT_COPILOT_EMBEDDING_MODEL)
    exit(0)

copilot_embedding_config_file = open(copilot_embedding_config_dir)
copilot_embedding_models = json.load(copilot_embedding_config_file)
copilot_embedding_config_file.close()

if copilot_embedding_models and "aiInferenceModels" in copilot_embedding_models and copilot_embedding_models["aiInferenceModels"]:
    for ai_inference_model in copilot_embedding_models["aiInferenceModels"]:
        if ai_inference_model["default"]:
            print("cloudera:" + ai_inference_model["name"])
            exit(0)
if copilot_embedding_models and "thirdPartyModels" in copilot_embedding_models and copilot_embedding_models["thirdPartyModels"]:
    for third_party_model in copilot_embedding_models["thirdPartyModels"]:
        if third_party_model["default"]:
            # Currently only Bedrock models are supported. In the future, we will need to read the provider_id from a different field.
            if "claude" in third_party_model["name"]:
                print("bedrock-chat:" + third_party_model["name"])
            else:
                print("bedrock:" + third_party_model["name"])
            exit(0)
print(DEFAULT_COPILOT_EMBEDDING_MODEL)
