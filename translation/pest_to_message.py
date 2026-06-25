"""
Translation layer: Pest degree-day data → farmer-readable WhatsApp alert.
Only HIGH and MEDIUM risk levels generate messages. MINIMAL/LOW = silence.
"""


def translate_pest_risk(dd_data: dict, humidity_risk: str = "LOW") -> str | None:
    """
    Convert pest degree-day data into an actionable WhatsApp alert.

    Args:
        dd_data:       Dict from PestModel.add_daily_reading()
        humidity_risk: Result from check_humidity_pest_risk()

    Returns:
        Formatted alert string, or None (no alert needed)
    """
    pest_name = dd_data.get("pest", "Unknown Pest")
    is_high   = dd_data["risk_level"] == "HIGH"   or humidity_risk == "HIGH"
    is_med    = dd_data["risk_level"] == "MEDIUM" or humidity_risk == "MEDIUM"

    if is_high:
        return (
            f"*PEST ALERT — {pest_name}*\n"
            f"Risk Level: HIGH\n\n"
            f"Your crop is in the danger window.\n\n"
            f" What to do:\n"
            f"1. Scout your farm tomorrow morning\n"
            f"2. Look for early signs of damage\n"
            f"3. Consider preventive spray\n"
            f"4. Contact your extension agent\n\n"
            f"Early action prevents 70% of crop loss!\n"
            f"_Reply SIGNS to learn what to look for_"
        ).strip()

    if is_med:
        return (
            f"*Pest Advisory — {pest_name}*\n"
            f"Risk Level: MODERATE\n\n"
            f"Conditions are building. No emergency yet.\n"
            f"- Monitor your farm twice this week\n"
            f"- Check undersides of leaves\n"
            f"- Prepare your spray equipment\n\n"
            f"_No immediate action required_"
        ).strip()

    return None


def get_pest_signs_message(pest_name: str) -> str:
    """Return visual signs to look for in the field for a given pest."""
    SIGNS = {
        "Fall Armyworm": (
            "*Fall Armyworm — Signs to Look For*\n\n"
            "- Small round holes in leaves (early)\n"
            "- Sawdust-like frass (droppings) in leaf whorls\n"
            "- Ragged leaf edges with brown margins\n"
            "- Larvae in the whorl — pale green with head capsule\n\n"
            "Act early. Spray neem oil or approved insecticide at dusk."
        ),
        "Maize Stem Borer": (
            "*Maize Stem Borer — Signs to Look For*\n\n"
            "- Dead heart (central leaf dies while outer leaves stay green)\n"
            "- Small entry holes in stem near soil level\n"
            "- Fine sawdust along stem\n"
            "- Stem breaks easily when pushed\n\n"
            "Scout at tillering stage (3-4 weeks after emergence)."
        ),
        "Tomato Late Blight": (
            "*Late Blight — Signs to Look For*\n\n"
            "- Water-soaked lesions on lower leaves\n"
            "- White-grey mould on underside of leaves\n"
            "- Brown-black patches on fruit\n"
            "- Spreads rapidly in wet, humid weather\n\n"
            "Apply fungicide immediately. Remove and destroy infected plants."
        ),
        "Desert Locust": (
            "*Desert Locust — Signs to Look For*\n\n"
            "- Swarms visible in the sky or settled on crops\n"
            "- Crops stripped of leaves within hours\n"
            "- Egg pods in sandy or bare soil\n\n"
            "Report sightings to your state ADP immediately."
        ),
        "Aphids": (
            "*Aphids — Signs to Look For*\n\n"
            "- Clusters of tiny green/black insects on young shoots and leaf undersides\n"
            "- Curled, yellowing or stunted leaves\n"
            "- Sticky honeydew on leaves (attracts ants and sooty mould)\n\n"
            "Spray with neem oil or soapy water. Ladybirds are natural predators."
        ),
        "Thrips": (
            "*Thrips — Signs to Look For*\n\n"
            "- Silver or bronze streaks on leaves\n"
            "- Black specks (frass) on leaves\n"
            "- Distorted or stunted growth\n"
            "- Flowers drop prematurely (especially onion/pepper)\n\n"
            "Spray early morning with neem oil or insecticidal soap."
        ),
        "Whiteflies": (
            "*Whiteflies — Signs to Look For*\n\n"
            "- Tiny white flying insects when leaves are shaken\n"
            "- Yellowing and dropping leaves\n"
            "- Sticky honeydew on upper leaf surfaces\n"
            "- Sooty black mould growing on honeydew\n\n"
            "Use yellow sticky traps. Spray neem oil on leaf undersides."
        ),
        "Mealybugs": (
            "*Mealybugs — Signs to Look For*\n\n"
            "- White cotton-like masses on stems, leaf joints, and fruit\n"
            "- Stunted growth and yellowing leaves\n"
            "- Sticky honeydew and sooty mould\n\n"
            "Wipe with alcohol-soaked cloth. Spray neem oil. Prune affected parts."
        ),
        "Cowpea Pod Borer": (
            "*Cowpea Pod Borer — Signs to Look For*\n\n"
            "- Small holes in flower buds and young pods\n"
            "- Frass (droppings) near entry holes\n"
            "- Damaged pods fail to develop or have deformed seeds\n"
            "- Larvae inside pods (pinkish with dark head)\n\n"
            "Spray at flowering stage. Remove and destroy infested pods."
        ),
        "Spider Mites": (
            "*Spider Mites — Signs to Look For*\n\n"
            "- Tiny yellow/brown speckles on upper leaf surface\n"
            "- Fine webbing on undersides of leaves\n"
            "- Leaves turn bronze and dry up\n"
            "- Worse in hot, dry weather\n\n"
            "Spray water on undersides. Use neem oil or sulphur spray."
        ),
        "Leaf Miners": (
            "*Leaf Miners — Signs to Look For*\n\n"
            "- Winding white or yellow tunnels (mines) visible inside leaves\n"
            "- Leaves look like they have serpentine trails\n"
            "- Affected leaves dry and drop early\n\n"
            "Remove affected leaves. Spray neem oil. Encourage parasitic wasps."
        ),
        "Cassava Green Mite": (
            "*Cassava Green Mite — Signs to Look For*\n\n"
            "- Tiny green mites on undersides of young leaves\n"
            "- Speckled yellow/brown discolouration\n"
            "- Leaves become distorted, smaller, and drop\n"
            "- Shoot tips may die back (candle-stick appearance)\n\n"
            "Plant resistant varieties. Spray neem or sulphur in early infestation."
        ),
        "Banana Weevil": (
            "*Banana Weevil — Signs to Look For*\n\n"
            "- Yellowing and wilting of leaves\n"
            "- Small holes at base of pseudostem\n"
            "- Frass (sawdust-like) oozing from stem holes\n"
            "- Plant suckers weak or failing to grow\n"
            "- Plants fall over easily in wind\n\n"
            "Use clean suckers from uninfested fields. Apply weevil traps at base."
        ),
        "Yam Beetle": (
            "*Yam Beetle — Signs to Look For*\n\n"
            "- Round holes bored into tubers\n"
            "- Frass around entry holes\n"
            "- Tubers rot in storage from entry wounds\n"
            "- Leaves may show minor feeding damage\n\n"
            "Treat setts before planting. Rotate yam plots annually."
        ),
        "Grain Weevil": (
            "*Grain Weevil (Storage) — Signs to Look For*\n\n"
            "- Small round holes in stored grains\n"
            "- Fine powdery dust at bottom of storage container\n"
            "- Adult weevils (small brown/black beetles) in grain\n"
            "- Grains become hollow and float in water\n\n"
            "Store grains in airtight containers. Add neem leaves to storage."
        ),
        "Black Pod Disease": (
            "*Black Pod Disease — Signs to Look For*\n\n"
            "- Brown/black water-soaked spots on cocoa pods\n"
            "- White fungal growth on infected pods in wet weather\n"
            "- Pods rot completely within 2-3 weeks\n"
            "- Blackened internal beans\n\n"
            "Remove and bury infected pods. Improve canopy ventilation. Apply copper fungicide."
        ),
        "Root Knot Nematode": (
            "*Root Knot Nematode — Signs to Look For*\n\n"
            "- Plants look stunted, yellow, and wilt even with adequate water\n"
            "- Roots have knobby galls (swellings/knots)\n"
            "- Poor yield with small fruit or tubers\n"
            "- Worse in sandy soils\n\n"
            "Rotate with marigold or cowpea. Add compost to improve soil health."
        ),
    }
    return SIGNS.get(
        pest_name,
        "Scout your farm early morning. Look for unusual leaf damage, "
        "frass, or insects. Contact your extension agent if in doubt.",
    )


def get_scouting_guide(crop: str) -> str:
    """Return step-by-step scouting instructions for the farmer's crop."""
    crop_lower = crop.lower()
    crop_display = crop_lower.replace("_", " ").title()

    crop_specific = {
        "tomato": (
            "Focus on lower leaves first — blight starts there.\n"
            "Check fruit for dark spots and cracks.\n"
            "Look for caterpillars inside fruits."
        ),
        "pepper": (
            "Check flowers and young fruit for thrips damage.\n"
            "Look for aphid colonies on new shoots.\n"
            "Inspect roots for galls (nematode damage)."
        ),
        "cowpea": (
            "Focus on flowers and young pods — pod borer attacks there.\n"
            "Look for entry holes with frass.\n"
            "Check leaf undersides for aphids."
        ),
        "cocoa": (
            "Check pods for black/brown water-soaked spots.\n"
            "Look for mealybugs in leaf axils.\n"
            "Check canopy for dieback."
        ),
        "cassava": (
            "Look for spider mites on young leaves.\n"
            "Check for whiteflies on leaf undersides.\n"
            "Inspect stems for mealybug masses."
        ),
        "onion": (
            "Look for silver streaks (thrips damage) on leaves.\n"
            "Check leaf axils for tiny black thrips.\n"
            "Inspect bulbs for rot at base."
        ),
    }

    extra = crop_specific.get(crop_lower, "Look at leaves, stems, fruit/pods, and soil near the base.")

    return (
        f"*Farm Scouting Guide — {crop_display}*\n\n"
        f"1. Go to your farm early morning (7-9 AM)\n"
        f"2. Walk in a W-pattern across your plot\n"
        f"3. Check 5 plants at each stopping point\n"
        f"4. {extra}\n"
        f"5. Count any insects or damage you see\n"
        f"6. If you find damage: reply SIGNS for what to look for\n\n"
        f"_Scout at least twice a week during pest alert periods_"
    )