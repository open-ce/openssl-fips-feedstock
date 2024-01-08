#include <stdio.h>
#include <stdlib.h>

#include <openssl/provider.h>

int main(void)
{
    OSSL_PROVIDER *fips;

    /* Load fips providers into the default (NULL) library context */
    fips = OSSL_PROVIDER_load(NULL, "fips");
    if (fips == NULL) {
        printf("Failed to load fips provider\n");
        exit(EXIT_FAILURE);
    }
    printf("Success");
    exit(EXIT_SUCCESS);
}
