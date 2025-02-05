scratchName=$1
days=$2
devHub=$3

# sf org create scratch -a "$scratchName" -y "$days" --definition-file config/my-agentforce-project-scratch-def.json --target-dev-hub "$devHub"

sf package install -p 04tKc0000004djU -w 30 -o "$scratchName" --no-prompt

sf package install -p 04t6S000001MTuJ -w 30 -o "$scratchName" --no-prompt

sf data tree import --plan ./data/OM/plain_plan.json -o "$scratchName"

sf project deploy start -o "$scratchName"

sf apex run -f ./config/CreateSettings.apex -o "$scratchName"
sf apex run -f ./config/CreateCalculationTypeAndActivatePromo.apex -o "$scratchName"

echo "Scratch org was created!"
echo "Do you want to open it in browser? Please answer yes or no."

while true; do
    read -p "Answer: " yn
    case $yn in
        [Yy]* ) sf org open -o "$scratchName"; break;;
        [Nn]* ) exit;;
        * ) echo "Do you want to open it in browser? Please answer yes or no.";;
    esac
done