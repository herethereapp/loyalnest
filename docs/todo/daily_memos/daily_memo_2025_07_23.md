### Daily Memo - Wednesday, July 23, 2025  
**Time: 1:38 AM JST**  
**Project: LoyalNest Shopify App Development**  

#### Overview
Today’s focus was on resolving configuration and dependency issues for the `frontend` app within the Nx monorepo, aligning with the 7–8 month TVP timeline for a customizable loyalty and rewards program. Key progress was made on stabilizing the development environment, with successful builds and serves, paving the way for Shopify integration and core feature development.

#### Key Achievements
- **Build Success**: Confirmed `npx nx build frontend --verbose` completes successfully, generating output in `dist/apps/frontend` with resolved `paths` for `src/main.tsx`, `src/styles.css`, `./app/app`, and `./nx-welcome`.
- **Serve Target Fixed**: Resolved the `Unable to resolve @nx/vite:dev` error by correcting the `serve` executor in `project.json` from `@nx/vite:dev-serve` to `@nx/vite:dev-server` and adding `buildTarget: "frontend:build"`. Successfully ran `npx nx serve frontend` at `http://localhost:4200`.
- **Dependency Management**: Addressed peer dependency conflicts (e.g., `nx@21.3.2` vs. `@nx/devkit@21.3.1`) using `npm install --legacy-peer-deps`, ensuring a functional setup despite warnings.
- **Executor Verification**: Confirmed `executors.json` exists in `@nx/vite`, resolving the initial executor lookup issue after reinstallation.

#### Challenges
- **Port Discrepancy**: Encountered conflicting ports (`3000`, `5173`, `4200`) due to misaligned `project.json` and `vite.config.ts` settings, resolved by standardizing on `4200`.
- **Dependency Conflicts**: The `ERESOLVE` error required workarounds with `--legacy-peer-deps`, indicating a need for future version alignment of Nx packages.
- **Executor Misconfiguration**: Initial `dev-serve` typo and missing `buildTarget` caused serve failures, requiring manual correction.

#### Next Steps
- **Shopify Integration**: Install `@shopify/app-bridge-react` and `@shopify/polaris` with `npm install --save --legacy-peer-deps`, update `vite.config.ts` with `optimizeDeps`, and test Polaris components.
- **Feature Development**: Begin implementing Must Have features (e.g., points system, SMS/email referrals, basic RFM analytics) using the stabilized environment.
- **QA and Testing**: Conduct in-house UI/UX testing on the serving app, ensuring compatibility with Shopify POS and offline mode.
- **Version Alignment**: Plan a maintenance phase to align all Nx packages (e.g., `@nx/devkit`, `@nx/vite`) to `21.3.2` to eliminate legacy peer dep warnings.

#### Notes
- Use `--verbose` flags for debugging to track resolution steps.
- Monitor runtime behavior after Shopify integration to catch any dependency-related issues.
- Commit changes regularly to maintain a clean Git history, e.g., `git commit -m "Integrate Shopify dependencies"`.

#### Action Items
- [ ] Integrate Shopify dependencies by 2:00 AM JST.
- [ ] Test and verify core features by end of day.
- [ ] Schedule version alignment review for next week.

**Prepared by: Grok 3 (xAI)**  
**For: LoyalNest Development Team**