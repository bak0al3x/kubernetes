# Run a React app in Kubernetes

## 1. Create a new react app

### 1.1. Pre-Requisites

First step is to install `nodejs` and `npm` (node package manager) packages on our system. To do so, execute the following command:

```bash
$ sudo pacman -S nodejs npm
```

For managing node versions, I like to use an npm package called `n`. With this, we can easily switch between different versions of nodejs.
To install it, execute the following command:

```bash
$ sudo npm i -g n
```

*NOTE: Sudo rights are required for this installation, as the `-g` switch tells to npm to install the provided package globally, hence the npm will try to write locations which may not be available for normal users.*

As for now, I'll stick with the LTS version of nodejs. To do so, execute the following command:

```bash
$ sudo n lts
  installing : node-v16.13.0
       mkdir : /usr/local/n/versions/node/16.13.0
       fetch : https://nodejs.org/dist/v16.13.0/node-v16.13.0-linux-x64.tar.xz
   installed : v16.13.0 (with npm 8.1.0)
```

For the last step, install `Create React App` globally:

```bash
sudo npm i -g create-react-app
```

### 1.2. Create the example app

You can easily create a new Reactjs application via the create-react-app command, execute the following command:

```bash
$ create-react-app frontend --template typescript
```

*NOTE: Use of typescript template is not mandatory*

### 1.3. Testing the example app

First you have to start a node development server locally. To accomplish this task you have to execute the following command from the project's root directory:

```bash
$ npm start
```

On Linux, this opens a new tab in your default browser, and opens the `http://localhost:3000` address. Now you can close the tab in the browser, also you can stop your loval node dev server.