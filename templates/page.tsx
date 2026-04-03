import { getSignInUrl, withAuth } from '@workos-inc/authkit-nextjs'
import { redirect } from 'next/navigation'
import { Button } from '@/components/ui/button'

export default async function Home() {
  const { user } = await withAuth()

  if (user) {
    redirect('/dashboard')
  }

  const signInUrl = await getSignInUrl()

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="mx-auto max-w-sm text-center">
        <h1 className="text-3xl font-bold tracking-tight">__PROJECT_NAME__</h1>
        <p className="mt-3 text-muted-foreground">
          Get started by signing in.
        </p>
        <Button asChild className="mt-6">
          <a href={signInUrl}>Sign in</a>
        </Button>
      </div>
    </div>
  )
}
