import { Container, Row, Col, Image } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { FiGithub, FiTerminal, FiShield, FiZap } from 'react-icons/fi';
import logo from '/logo.png';

function HomePage() {
  return (
    <div>
      {/* Hero Section */}
      <section className="hero-section">
        <Container>
          <Row className="justify-content-center text-center">
            <Col lg={8}>
              <Image src={logo} alt="ursh" height="120" className="mb-4" />
              <h1 className="mb-3">Ursh Registry</h1>
              <p className="lead mb-4">
                Discover and share shell scripts. Like npx or uvx, but for shell scripts.
              </p>
              <div className="d-flex gap-3 justify-content-center flex-wrap">
                <Link to="/browse" className="btn btn-light btn-lg">
                  Browse Urshies
                </Link>
                <Link to="/submit" className="btn btn-outline-light btn-lg">
                  <FiGithub className="me-2" />
                  Submit Urshie
                </Link>
              </div>
            </Col>
          </Row>
        </Container>
      </section>

      {/* Features Section */}
      <section className="py-5">
        <Container>
          <Row className="text-center mb-5">
            <Col>
              <h2 className="fw-bold">Why Ursh?</h2>
              <p className="text-muted">A better way to share and run shell scripts</p>
            </Col>
          </Row>
          <Row className="g-4">
            <Col md={3}>
              <div className="text-center p-4">
                <FiTerminal className="display-4 text-primary mb-3" />
                <h5>Easy to Use</h5>
                <p className="text-muted">
                  Run scripts with a single command: <code>ursh gh:user/repo/script.sh</code>
                </p>
              </div>
            </Col>
            <Col md={3}>
              <div className="text-center p-4">
                <FiShield className="display-4 text-primary mb-3" />
                <h5>Safe & Secure</h5>
                <p className="text-muted">
                  Preview scripts before running with dry-run mode and isolation guards
                </p>
              </div>
            </Col>
            <Col md={3}>
              <div className="text-center p-4">
                <FiZap className="display-4 text-primary mb-3" />
                <h5>Fast & Cached</h5>
                <p className="text-muted">
                  Scripts are cached locally for instant subsequent runs
                </p>
              </div>
            </Col>
            <Col md={3}>
              <div className="text-center p-4">
                <FiGithub className="display-4 text-primary mb-3" />
                <h5>GitHub Integration</h5>
                <p className="text-muted">
                  Use GitHub shorthand and host your scripts on GitHub
                </p>
              </div>
            </Col>
          </Row>
        </Container>
      </section>

      {/* CTA Section */}
      <section className="py-5 bg-light">
        <Container>
          <Row className="align-items-center">
            <Col lg={6}>
              <h3>Ready to get started?</h3>
              <p className="lead">
                Install ursh and start running scripts from the registry.
              </p>
              <pre className="bg-dark text-light p-3 rounded">
                curl -sSL day50.dev/ursh | bash
              </pre>
            </Col>
            <Col lg={6} className="text-lg-end">
              <Link to="/browse" className="btn btn-primary btn-lg">
                Explore the Registry
              </Link>
            </Col>
          </Row>
        </Container>
      </section>
    </div>
  );
}

export default HomePage;
