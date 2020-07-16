import React from 'react';
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Redirect,
} from 'react-router-dom';
import {useAuth} from './components/AuthProvider';
import Login from './components/Login';
import Register from './components/Register';
import Demo from './components/Demo';
import Dashboard from './components/Dashboard';
import Widget from './components/Widget';
import './App.css';

const App = () => {
  const auth = useAuth();

  if (auth.loading) {
    return null; // FIXME: show loading icon
  }

  if (!auth.isAuthenticated) {
    return (
      <Router>
        <Switch>
          <Route path="/demo" component={Demo} />
          <Route path="/login" component={Login} />
          <Route path="/register" component={Register} />
          <Route path="/widget" component={Widget} />
          <Route path="*" render={() => <Redirect to="/login" />} />
        </Switch>
      </Router>
    );
  }

  return (
    <Router>
      <Switch>
        <Route exact path="/" component={Demo} />
        <Route path="/login" component={Login} />
        <Route path="/register" component={Register} />
        <Route path="/widget" component={Widget} />
        <Route path="/conversations" component={Dashboard} />
        <Route path="*" render={() => <Redirect to="/conversations" />} />
      </Switch>
    </Router>
  );
};

export default App;
