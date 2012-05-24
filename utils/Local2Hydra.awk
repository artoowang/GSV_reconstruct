#!/bin/awk -f

/\/localdisk\// {
    sub("localdisk", "hydra/S4");
    sub("resize", "hydra_links/resize");
    print;
}

/localdisk_b/ {
    sub("localdisk_b", "hydra/4b");
    print;
}

/localdisk_c/ {
    sub("localdisk_c", "hydra/4c");
    print;
}
