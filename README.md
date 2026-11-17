# Lailao Analytics SDKs

Official source for the Lailao Analytics event clients. MIT licensed.

- [Web, React and Next.js](sdk/web): ESM JavaScript client with TypeScript declarations.
- [Flutter](sdk/flutter): explicit screen, session and engagement tracking.

Service: https://analytics.lailaolab.com

## Install

Web / React / Next.js:

```sh
npm install @sksouk/lailao-analytics
```

Flutter:

```sh
flutter pub add lailao_analytics
```

- npm: https://www.npmjs.com/package/@sksouk/lailao-analytics
- pub.dev: https://pub.dev/packages/lailao_analytics

Both SDKs are released as version 0.1.0. See their READMEs for integration,
privacy, explicit tracking and error-handling details.

## Security and privacy

SDK keys allow event ingestion only. Never embed OAuth client secrets or dashboard
credentials. Inform your users about analytics and request consent where required.
No events are sent automatically; call the SDK explicitly. See each package README
for collected fields, supported features and limitations.

## Verify source

Web checks: `cd sdk/web && npm test && npm pack --dry-run`.
Flutter checks: `cd sdk/flutter && flutter pub get && flutter analyze && flutter pub publish --dry-run`.

A registry listing, verified publisher badge, or provenance attestation is evidence
of identity/source, not a guarantee of software safety or permission to bypass an
organization's download policy.
