import Link from "next/link";
import { Film } from "lucide-react";

export function Logo() {
  return <Link className="logo" href="/" aria-label="Dramabyte home"><Film size={23} /><span>Drama<span>byte</span></span></Link>;
}
