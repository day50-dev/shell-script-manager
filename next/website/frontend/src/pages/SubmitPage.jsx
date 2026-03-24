import { useState } from 'react';
import { Container, Row, Col, Form, Button, Card, Alert, Spinner } from 'react-bootstrap';
import { useNavigate } from 'react-router-dom';
import { urshiesAPI } from '../services/api';
import AlertMessage from '../components/AlertMessage';
import { FiInfo, FiZap } from 'react-icons/fi';

function SubmitPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [inferProgress, setInferProgress] = useState(null);
  const [formData, setFormData] = useState({
    url: ''
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setSuccess(null);
    setInferProgress({ stage: 'fetching', message: 'Fetching script...' });

    try {
      // Submit URL for inference
      const response = await urshiesAPI.inferAndCreate(formData.url);
      
      setInferProgress({ stage: 'complete', message: 'Inference complete!' });
      setSuccess(`Urshie "${response.manifest.name}" inferred and submitted!`);
      
      setTimeout(() => {
        navigate(`/urshies/${response.id}`);
      }, 1500);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to infer and submit urshie');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container className="py-4">
      <Row className="mb-4">
        <Col>
          <h2>Submit an Urshie</h2>
          <p className="text-muted">Just paste the URL. We'll infer everything else.</p>
        </Col>
      </Row>

      <Row>
        <Col lg={8}>
          <Card>
            <Card.Body>
              {error && <AlertMessage variant="danger" message={error} />}
              {success && <AlertMessage variant="success" message={success} />}

              {inferProgress && (
                <Alert variant="info" className="mb-3">
                  <Spinner animation="border" size="sm" className="me-2" />
                  {inferProgress.message}
                </Alert>
              )}

              <Form onSubmit={handleSubmit}>
                <Form.Group className="mb-3">
                  <Form.Label>Script URL *</Form.Label>
                  <Form.Control
                    type="text"
                    name="url"
                    value={formData.url}
                    onChange={handleChange}
                    placeholder="gh:user/repo/script.sh or https://..."
                    required
                  />
                  <Form.Text className="text-muted">
                    GitHub shorthand (gh:user/repo/file.sh) or any raw script URL.
                    We'll automatically find the homepage, analyze privileges, and generate the manifest.
                  </Form.Text>
                </Form.Group>

                <div className="d-grid gap-2">
                  <Button
                    type="submit"
                    variant="primary"
                    size="lg"
                    disabled={loading || !!inferProgress}
                  >
                    <FiZap className="me-2" />
                    {loading ? 'Inferring...' : 'Auto-Infer & Submit'}
                  </Button>
                </div>
              </Form>
            </Card.Body>
          </Card>
        </Col>

        <Col lg={4}>
          <Card className="bg-light">
            <Card.Body>
              <h5 className="d-flex align-items-center">
                <FiInfo className="me-2" />
                How Inference Works
              </h5>
              <ul className="mt-3 mb-0 small">
                <li className="mb-2">
                  <strong>Pass 1 - Discovery:</strong> We fetch your script and search for the project homepage
                </li>
                <li className="mb-2">
                  <strong>Pass 2 - Cross-Verify:</strong> We verify the homepage links back to your script
                </li>
                <li className="mb-2">
                  <strong>Pass 3 - Analysis:</strong> We analyze privileges, tools used, and security risks
                </li>
                <li className="mb-2">
                  <strong>Result:</strong> A complete manifest is generated automatically
                </li>
              </ul>
            </Card.Body>
          </Card>

          <Card className="bg-light mt-3">
            <Card.Body>
              <h5>Supported URL Formats</h5>
              <ul className="mt-2 mb-0 small">
                <li><code>gh:user/repo/script.sh</code> - GitHub shorthand</li>
                <li><code>gl:user/repo/script.sh</code> - GitLab shorthand</li>
                <li><code>https://raw.githubusercontent.com/...</code></li>
                <li><code>https://gitlab.com/.../-/raw/...</code></li>
                <li>Any direct HTTPS URL to raw script content</li>
              </ul>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}

export default SubmitPage;
