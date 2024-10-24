() => {
    let params;
    const chain = {
        steps: [
            {
                id: "authorize_1_choose_cc",
                zencode: "Given I have a 'string' named 'form_input_and_params'\nWhen I create json unescaped object of 'form_input_and_params'\nThen print the data from 'json_unescaped_object'",
                onAfter: (result, zencode) => {
                    const jsonResult = JSON.parse(result)
                    authroizeCustomChain.steps[1] = {
                            id: "authorize_2_custom_code",
                            zencodeFromFile: `authz_server/custom_code/${jsonResult.custom_code}.zen`,
                            keysFromFile: `authz_server/custom_code/${jsonResult.custom_code}.keys.json`,
                            dataFromStep: "authorize_1_choose_cc",
                            dataTransform: (data) => {
                                return JSON.stringify((JSON.parse(data)).data)
                            }
                    }
                    params = jsonResult.params
                }
            },
            {},
            {
                id: "authorize_3_get_access_code",
                zencodeFromFile: "authz_server/ru_to_ac.zen",
                dataFromStep: "authorize_2_custom_code",
                keysFromFile: "authz_server/ru_to_ac.keys.json",
                dataTransform: (data) => {
                    return JSON.stringify({
                        ...(JSON.parse(data)),
                        ...params
                    })
                }
            },
        ]
    }
    globalThis.authroizeCustomChain = chain
    return chain
}