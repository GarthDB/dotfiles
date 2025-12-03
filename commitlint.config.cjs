module.exports = {
  extends: ["@commitlint/config-conventional"],
  ignores: [
    (message) => message.includes("[create-pull-request] automated change"),
  ],
};
