/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  NativeEventEmitter,
  DeviceEventEmitter,
  NativeModules,
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

export default class Hermes extends Component {
  emitter = DeviceEventEmitter

  constructor(props) {
    super(props)
    this.state = {
      trackerStatus: 'not initialized'
    }
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to React Native!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
        <Text>Tracker: {this.state.trackerStatus}</Text>
      </View>
    );
  }

  componentDidMount() {
    var tracker = NativeModules.Tracker;
    this.emitter.addListener(
      'onAccelerate',
      (result) => this.setState({
        trackerStatus: result.vector
      })
    );
    tracker.accelerometer();
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('Hermes', () => Hermes);
