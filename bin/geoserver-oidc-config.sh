#!/usr/bin/env sh
set -eu

GEOSERVER_AUTH="${GEOSERVER_AUTH:-admin:geoserver}"

# This script assumes both geoserver and geoserver-secure are healthy
# and configured exactly the same.
for GEOSERVER_HOST in geoserver geoserver-secure; do
  GEOSERVER_REST="http://${GEOSERVER_HOST}:8080/geoserver/rest"
  if [ "$GEOSERVER_HOST" = "geoserver-secure" ]; then
    CLIENT_ID="${OIDC_SECURE_CLIENT_ID}"
    CLIENT_SECRET="${OIDC_SECURE_CLIENT_SECRET}"
    HOST_PORT="8081"
  else
    CLIENT_ID="${OIDC_CLIENT_ID}"
    CLIENT_SECRET="${OIDC_CLIENT_SECRET}"
    HOST_PORT="8080"
  fi

  echo "Creating keycloak OIDC auth filter on ${GEOSERVER_HOST}..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --request POST \
    --url "${GEOSERVER_REST}/security/authfilters" \
    --user "${GEOSERVER_AUTH}" \
    --header 'Content-Type: application/xml; charset=utf-8' \
    --data "<org.geoserver.security.oauth2.login.GeoServerOAuth2LoginFilterConfig>
    <name>keycloak</name>
    <className>org.geoserver.security.oauth2.login.GeoServerOAuth2LoginAuthenticationFilter</className>
    <roleSource class=\"org.geoserver.security.oauth2.login.GeoServerOAuth2LoginFilterConfig\$OpenIdRoleSource\">IdToken</roleSource>
    <baseRedirectUri>http://localhost:${HOST_PORT}/geoserver/</baseRedirectUri>
    <googleEnabled>false</googleEnabled>
    <googleUserNameAttribute>email</googleUserNameAttribute>
    <googleRedirectUri>http://localhost:${HOST_PORT}/geoserver/web/login/oauth2/code/google</googleRedirectUri>
    <gitHubEnabled>false</gitHubEnabled>
    <gitHubUserNameAttribute>id</gitHubUserNameAttribute>
    <gitHubRedirectUri>http://localhost:${HOST_PORT}/geoserver/web/login/oauth2/code/gitHub</gitHubRedirectUri>
    <msEnabled>false</msEnabled>
    <msUserNameAttribute>sub</msUserNameAttribute>
    <msRedirectUri>http://localhost:${HOST_PORT}/geoserver/web/login/oauth2/code/microsoft</msRedirectUri>
    <msScopes>openid profile email</msScopes>
    <oidcEnabled>true</oidcEnabled>
    <oidcClientId>${CLIENT_ID}</oidcClientId>
    <oidcClientSecret>${CLIENT_SECRET}</oidcClientSecret>
    <oidcUserNameAttribute>email</oidcUserNameAttribute>
    <oidcRedirectUri>http://localhost:${HOST_PORT}/geoserver/web/login/oauth2/code/oidc</oidcRedirectUri>
    <oidcScopes>openid  berkeley_edu_groups email profile</oidcScopes>
    <oidcDiscoveryUri>http://keycloak:8180/realms/berkeley-local/.well-known/openid-configuration</oidcDiscoveryUri>
    <oidcTokenUri>http://keycloak:8180/realms/berkeley-local/protocol/openid-connect/token</oidcTokenUri>
    <oidcAuthorizationUri>http://keycloak.localhost:8180/realms/berkeley-local/protocol/openid-connect/auth</oidcAuthorizationUri>
    <oidcUserInfoUri>http://keycloak:8180/realms/berkeley-local/protocol/openid-connect/userinfo</oidcUserInfoUri>
    <oidcJwkSetUri>http://keycloak:8180/realms/berkeley-local/protocol/openid-connect/certs</oidcJwkSetUri>
    <oidcLogoutUri>http://keycloak.localhost:8180/realms/berkeley-local/protocol/openid-connect/logout</oidcLogoutUri>
    <oidcForceAuthorizationUriHttps>false</oidcForceAuthorizationUriHttps>
    <oidcForceTokenUriHttps>false</oidcForceTokenUriHttps>
    <oidcEnforceTokenValidation>true</oidcEnforceTokenValidation>
    <oidcUsePKCE>false</oidcUsePKCE>
    <oidcAuthenticationMethodPostSecret>false</oidcAuthenticationMethodPostSecret>
    <oidcAllowUnSecureLogging>false</oidcAllowUnSecureLogging>
    <tokenRolesClaim>preferred_username</tokenRolesClaim>
    <postLogoutRedirectUri>http://localhost:${HOST_PORT}/geoserver/web/</postLogoutRedirectUri>
    <enableRedirectAuthenticationEntryPoint>true</enableRedirectAuthenticationEntryPoint>
    <msGraphMemberOf>false</msGraphMemberOf>
    <msGraphAppRoleAssignments>false</msGraphAppRoleAssignments>
    <roleConverterString>testadmin=ADMIN</roleConverterString>
    <onlyExternalListedRoles>false</onlyExternalListedRoles>
  </org.geoserver.security.oauth2.login.GeoServerOAuth2LoginFilterConfig>")

  case "$HTTP_STATUS" in
    200|201) echo "Auth filter created." ;;
    *)   echo "ERROR: Unexpected status creating auth filter on ${GEOSERVER_HOST}: $HTTP_STATUS"; exit 1 ;;
  esac

  echo "Updating web filter chain on ${GEOSERVER_HOST}..."
  FILTER_CHAIN_UPDATE_HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    --request PUT \
    --url "${GEOSERVER_REST}/security/filterchain/web" \
    --user "${GEOSERVER_AUTH}" \
    --header 'Content-Type: application/xml; charset=utf-8' \
    --data '<filters name="web" class="org.geoserver.security.HtmlLoginFilterChain" path="/web/**,/gwc/rest/web/**,/" disabled="false" allowSessionCreation="true" ssl="false" matchHTTPMethod="false" interceptorName="interceptor" exceptionTranslationName="exception">
      <filter>rememberme</filter>
      <filter>form</filter>
      <filter>keycloak</filter>
      <filter>anonymous</filter>
    </filters>')

  case "$FILTER_CHAIN_UPDATE_HTTP_STATUS" in
    200) echo "Web filter chain updated." ;;
    *)   echo "ERROR: Unexpected status updating web filter chain: $FILTER_CHAIN_UPDATE_HTTP_STATUS"; exit 1 ;;
  esac

  echo "Done with ${GEOSERVER_HOST}."
done
